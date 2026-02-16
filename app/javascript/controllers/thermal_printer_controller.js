import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    saleId: Number
  }

  async connect() {
    console.log("🖨️ Thermal Printer Controller conectado")
  }

  // Método principal para imprimir
  async printTicket(saleId) {
    try {
      // 1. Verificar si hay impresora guardada
      const savedPrinter = this.getSavedPrinter()
      
      if (!savedPrinter) {
        // Primera vez: Pedir seleccionar impresora
        await this.selectAndSavePrinter()
      }
      
      // 2. Obtener comandos ESC/POS del servidor
      const commands = await this.fetchEscposCommands(saleId)
      
      // 3. Conectar a la impresora
      const device = await this.connectToPrinter()
      
      if (!device) {
        throw new Error("No se pudo conectar a la impresora")
      }
      
      // 4. Enviar comandos a la impresora
      await this.sendCommands(device, commands)
      
      console.log("✅ Ticket impreso correctamente")
      
    } catch (error) {
      console.error("❌ Error al imprimir:", error)
      this.handlePrintError(error)
    }
  }

  // Obtener impresora guardada de localStorage
  getSavedPrinter() {
    const saved = localStorage.getItem('thermal_printer_config')
    return saved ? JSON.parse(saved) : null
  }

  // Guardar impresora en localStorage
  savePrinter(device) {
    const config = {
      vendorId: device.vendorId,
      productId: device.productId,
      productName: device.productName,
      manufacturerName: device.manufacturerName,
      serialNumber: device.serialNumber
    }
    localStorage.setItem('thermal_printer_config', JSON.stringify(config))
    console.log("💾 Impresora guardada:", config)
  }

  // Pedir al usuario que seleccione impresora
  async selectAndSavePrinter() {
    try {
      const device = await navigator.usb.requestDevice({
        filters: [
          { classCode: 7 } // Clase de impresoras
        ]
      })
      
      this.savePrinter(device)
      return device
      
    } catch (error) {
      if (error.name === 'NotFoundError') {
        throw new Error("No se seleccionó ninguna impresora")
      }
      throw error
    }
  }

  // Conectar a la impresora USB
  async connectToPrinter() {
    const savedPrinter = this.getSavedPrinter()
    
    if (!savedPrinter) {
      throw new Error("No hay impresora configurada")
    }

    // Obtener dispositivos USB disponibles
    const devices = await navigator.usb.getDevices()
    
    // Buscar la impresora guardada
    let device = devices.find(d => 
      d.vendorId === savedPrinter.vendorId && 
      d.productId === savedPrinter.productId
    )

    if (!device) {
      throw new Error(`Impresora "${savedPrinter.productName}" no encontrada. Ve a Config > Tickets para cambiar de impresora.`)
    }

    // Abrir conexión
    if (!device.opened) {
      await device.open()
    }

    // Seleccionar configuración
    if (device.configuration === null) {
      await device.selectConfiguration(1)
    }

    // Reclamar interface
    await device.claimInterface(0)

    return device
  }

  // Obtener comandos ESC/POS del servidor
  async fetchEscposCommands(saleId) {
    const response = await fetch(`/sales/${saleId}/print_ticket_escpos`)
    
    if (!response.ok) {
      throw new Error("Error al obtener comandos de impresión")
    }
    
    const data = await response.json()
    return data.commands
  }

  // Enviar comandos a la impresora
  async sendCommands(device, commands) {
    // Convertir array de strings a Uint8Array
    const fullText = commands.join('')
    const encoder = new TextEncoder()
    const data = encoder.encode(fullText)

    // Enviar a la impresora (endpoint 1 suele ser el de escritura)
    const endpointNumber = 1
    await device.transferOut(endpointNumber, data)

    console.log(`📤 Enviados ${data.length} bytes a la impresora`)
  }

  // Manejar errores
  handlePrintError(error) {
    let message = error.message

    if (error.message.includes("no encontrada")) {
      // Error de impresora no conectada
      alert(`❌ ${message}`)
    } else if (error.name === 'NotFoundError') {
      // Usuario canceló selección
      console.log("Usuario canceló selección de impresora")
    } else {
      // Error general
      alert(`❌ Error al imprimir: ${message}`)
    }
  }

  // Método para detectar impresoras (llamado desde settings)
  async detectPrinters() {
    try {
      const device = await this.selectAndSavePrinter()
      
      if (device) {
        alert(`✅ Impresora "${device.productName}" configurada correctamente`)
      }
      
    } catch (error) {
      console.error("Error al detectar impresoras:", error)
      alert("❌ Error al detectar impresoras")
    }
  }
}