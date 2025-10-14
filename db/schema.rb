# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_14_004356) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "barcodes", force: :cascade do |t|
    t.string "code"
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_barcodes_on_product_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone"
    t.string "email"
    t.text "address"
    t.string "rfc"
    t.decimal "credit_limit", precision: 10, scale: 2
    t.decimal "current_debt", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "customer_type", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_type"], name: "index_customers_on_customer_type"
    t.index ["email"], name: "index_customers_on_email"
    t.index ["name"], name: "index_customers_on_name"
    t.index ["phone"], name: "index_customers_on_phone"
    t.index ["rfc"], name: "index_customers_on_rfc"
  end

  create_table "inventories", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "warehouse_id", null: false
    t.decimal "quantity", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "minimum_quantity", precision: 12, scale: 2, default: "0.0", null: false
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "warehouse_id"], name: "index_inventories_on_product_id_and_warehouse_id", unique: true
    t.index ["product_id"], name: "index_inventories_on_product_id"
    t.index ["warehouse_id"], name: "index_inventories_on_warehouse_id"
  end

  create_table "inventory_adjustments", force: :cascade do |t|
    t.bigint "inventory_id", null: false
    t.decimal "quantity", precision: 10, scale: 3, null: false
    t.integer "adjustment_type", default: 0, null: false
    t.string "reason", null: false
    t.text "note"
    t.string "performed_by", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_id"], name: "index_inventory_adjustments_on_inventory_id"
  end

  create_table "inventory_movements", force: :cascade do |t|
    t.bigint "inventory_id", null: false
    t.string "movement_type", null: false
    t.string "reason"
    t.decimal "quantity", precision: 12, scale: 2, null: false
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_id"], name: "index_inventory_movements_on_inventory_id"
    t.index ["movement_type"], name: "index_inventory_movements_on_movement_type"
    t.index ["source_type", "source_id"], name: "index_inventory_movements_on_source"
    t.check_constraint "quantity > 0::numeric", name: "chk_inventory_movements_quantity_positive"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.decimal "stock_quantity"
    t.decimal "unit_conversion"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "purchase_unit_id", null: false
    t.bigint "sale_unit_id", null: false
    t.boolean "active", default: true, null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["purchase_unit_id"], name: "index_products_on_purchase_unit_id"
    t.index ["sale_unit_id"], name: "index_products_on_sale_unit_id"
  end

  create_table "purchase_items", force: :cascade do |t|
    t.bigint "purchase_id", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 12, scale: 2, null: false
    t.decimal "purchase_price", precision: 12, scale: 2, null: false
    t.decimal "conversion_factor", precision: 12, scale: 6, default: "1.0", null: false
    t.decimal "quantity_sale_units", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "cost_per_piece", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "subtotal", precision: 14, scale: 2, default: "0.0", null: false
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
    t.check_constraint "conversion_factor > 0::numeric", name: "chk_purchase_items_conversion_positive"
    t.check_constraint "purchase_price >= 0::numeric", name: "chk_purchase_items_unit_cost_nonnegative"
    t.check_constraint "quantity > 0::numeric", name: "chk_purchase_items_quantity_positive"
    t.check_constraint "quantity_sale_units > 0::numeric", name: "chk_purchase_items_quantity_sale_units_positive"
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "supplier_id", null: false
    t.bigint "warehouse_id", null: false
    t.date "purchase_date"
    t.decimal "total", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "processed_at"
    t.index ["processed_at"], name: "index_purchases_on_processed_at"
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
    t.index ["warehouse_id"], name: "index_purchases_on_warehouse_id"
  end

  create_table "sale_items", force: :cascade do |t|
    t.bigint "sale_id", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 10, scale: 3, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "discount", precision: 10, scale: 2, default: "0.0"
    t.decimal "subtotal", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "user_id"
    t.bigint "warehouse_id", null: false
    t.date "sale_date", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "payment_status", default: 0, null: false
    t.integer "payment_method", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["payment_status"], name: "index_sales_on_payment_status"
    t.index ["sale_date"], name: "index_sales_on_sale_date"
    t.index ["status"], name: "index_sales_on_status"
    t.index ["user_id"], name: "index_sales_on_user_id"
    t.index ["warehouse_id"], name: "index_sales_on_warehouse_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_suppliers_on_name"
  end

  create_table "units", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "barcodes", "products"
  add_foreign_key "inventories", "products"
  add_foreign_key "inventories", "warehouses"
  add_foreign_key "inventory_adjustments", "inventories"
  add_foreign_key "inventory_movements", "inventories"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "units", column: "purchase_unit_id"
  add_foreign_key "products", "units", column: "sale_unit_id"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "purchases", "warehouses"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "warehouses"
end
