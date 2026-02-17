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
    let device = null
    
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
      device = await this.connectToPrinter()
      
      if (!device) {
        throw new Error("No se pudo conectar a la impresora")
      }
      
      // 4. Enviar comandos a la impresora CON TIMEOUT
      await this.sendCommandsWithTimeout(device, commands, 10000) // 10 segundos timeout
      
      console.log("✅ Ticket impreso correctamente")
      
    } catch (error) {
      console.error("❌ Error al imprimir:", error)
      this.handlePrintError(error)
      
    } finally {
      // 🧹 CRÍTICO: Siempre limpiar conexión
      if (device && device.opened) {
        try {
          await device.close()
          console.log("🔌 Conexión USB cerrada correctamente")
        } catch (e) {
          console.warn('Error cerrando dispositivo:', e)
        }
      }
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
      throw new Error(`Impresora "${savedPrinter.productName}" no encontrada. Verifica que esté conectada o ve a Config > Tickets para cambiar de impresora.`)
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

  // 📍 Enviar comandos a la impresora (con detección automática de endpoint)
  async sendCommands(device, commands) {
    try {
      // Convertir array de strings a Uint8Array
      const fullText = commands.join('')
      const encoder = new TextEncoder()
      const data = encoder.encode(fullText)

      // 🎯 MEJORA: Detectar endpoint automáticamente
      const config = device.configurations[0]
      const iface = config.interfaces[0]
      const endpoint = iface.alternate.endpoints.find(
        ep => ep.direction === 'out'
      )

      if (!endpoint) {
        throw new Error('No se encontró endpoint de salida en la impresora')
      }

      // Enviar a la impresora
      await device.transferOut(endpoint.endpointNumber, data)

      console.log(`📤 Enviados ${data.length} bytes a la impresora (endpoint ${endpoint.endpointNumber})`)
      
    } catch (error) {
      // 🔌 MEJORA: Errores USB más claros
      if (error.name === 'NetworkError') {
        throw new Error('La impresora se desconectó durante la impresión. Verifica el cable USB.')
      } else if (error.name === 'InvalidStateError') {
        throw new Error('Error de conexión con la impresora. Intenta desconectar y volver a conectar.')
      } else if (error.message && error.message.includes('endpoint')) {
        throw new Error('Impresora incompatible o mal configurada. Intenta con método PDF en Config > Tickets.')
      }
      throw error
    }
  }

  // ⏱️ MEJORA: Enviar comandos CON TIMEOUT
  async sendCommandsWithTimeout(device, commands, timeout = 10000) {
    const sendPromise = this.sendCommands(device, commands)
    
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => {
        reject(new Error(`Timeout: La impresora no respondió en ${timeout/1000} segundos. Verifica que esté encendida y lista.`))
      }, timeout)
    })
    
    return Promise.race([sendPromise, timeoutPromise])
  }

  // Manejar errores
  handlePrintError(error) {
    let message = error.message
    let icon = 'error'

    // Mensajes personalizados según tipo de error
    if (message.includes('no encontrada') || message.includes('desconectó')) {
      icon = 'warning'
    } else if (message.includes('No se seleccionó')) {
      // Usuario canceló, no mostrar error
      console.log("Usuario canceló selección de impresora")
      return
    } else if (message.includes('Timeout')) {
      icon = 'warning'
    }

    alert(`❌ ${message}`)
  }

  // Método para detectar impresoras (llamado desde settings)
  async detectPrinters() {
    try {
      const device = await this.selectAndSavePrinter()
      
      if (device) {
        alert(`✅ Impresora "${device.productName}" configurada correctamente`)
        
        // Actualizar UI mostrando impresora guardada
        const statusDiv = document.getElementById('printer-status')
        if (statusDiv) {
          const config = this.getSavedPrinter()
          statusDiv.innerHTML = `
            <div class="p-2 bg-green-50 border border-green-200 rounded mt-3">
              ✅ Impresora configurada: <strong>${config.productName || 'Impresora USB'}</strong>
            </div>
          `
        }
      }
      
    } catch (error) {
      console.error("Error al detectar impresoras:", error)
      
      if (error.message !== "No se seleccionó ninguna impresora") {
        alert("❌ Error al detectar impresoras: " + error.message)
      }
    }
  }

  // Método para reimprimir desde show de venta
  async reprintTicket(event) {
    const button = event.currentTarget
    const saleId = button.dataset.saleId
    const printingMethod = button.dataset.printingMethod
    
    console.log('🔄 Reimprimiendo ticket:', saleId, 'Método:', printingMethod)
    
    if (printingMethod === 'webusb') {
      // Usar WebUSB
      await this.printTicket(saleId)
    } else {
      // Usar PDF (abrir en nueva ventana)
      window.open(`/sales/${saleId}/print_ticket`, '_blank')
    }
  }
}