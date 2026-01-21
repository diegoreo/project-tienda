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

ActiveRecord::Schema[8.0].define(version: 2026_01_20_225953) do
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

  create_table "cash_register_flows", force: :cascade do |t|
    t.bigint "register_session_id", null: false
    t.integer "movement_type", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.text "description", null: false
    t.bigint "created_by_id", null: false
    t.bigint "authorized_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "cancelled", default: false, null: false
    t.bigint "cancelled_by_id"
    t.datetime "cancelled_at"
    t.text "cancellation_reason"
    t.index ["authorized_by_id"], name: "index_cash_register_flows_on_authorized_by_id"
    t.index ["cancelled"], name: "index_cash_register_flows_on_cancelled"
    t.index ["cancelled_at"], name: "index_cash_register_flows_on_cancelled_at"
    t.index ["cancelled_by_id"], name: "index_cash_register_flows_on_cancelled_by_id"
    t.index ["created_at"], name: "index_cash_register_flows_on_created_at"
    t.index ["created_by_id"], name: "index_cash_register_flows_on_created_by_id"
    t.index ["movement_type"], name: "index_cash_register_flows_on_movement_type"
    t.index ["register_session_id", "movement_type"], name: "idx_on_register_session_id_movement_type_c1972de8a1"
    t.index ["register_session_id"], name: "index_cash_register_flows_on_register_session_id"
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
    t.index ["current_debt"], name: "index_customers_on_current_debt_positive", where: "(current_debt > (0)::numeric)"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "performed_by_id", null: false
    t.index ["inventory_id"], name: "index_inventory_adjustments_on_inventory_id"
    t.index ["performed_by_id"], name: "index_inventory_adjustments_on_performed_by_id"
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

  create_table "payment_applications", force: :cascade do |t|
    t.bigint "payment_id", null: false
    t.bigint "sale_id", null: false
    t.decimal "amount_applied", precision: 10, scale: 2, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id", "sale_id"], name: "index_payment_applications_on_payment_id_and_sale_id", unique: true
    t.index ["payment_id"], name: "index_payment_applications_on_payment_id"
    t.index ["sale_id"], name: "index_payment_applications_on_sale_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "sale_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "payment_date", null: false
    t.integer "payment_method", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "payment_date"], name: "index_payments_on_customer_id_and_payment_date"
    t.index ["customer_id"], name: "index_payments_on_customer_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["sale_id"], name: "index_payments_on_sale_id"
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
    t.integer "product_type", default: 0, null: false
    t.bigint "master_product_id"
    t.decimal "conversion_factor", precision: 10, scale: 3, default: "1.0", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["master_product_id"], name: "index_products_on_master_product_id"
    t.index ["product_type"], name: "index_products_on_product_type"
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
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "processed_at"
    t.index ["processed_at"], name: "index_purchases_on_processed_at"
    t.index ["purchase_date"], name: "index_purchases_on_purchase_date"
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
    t.index ["warehouse_id"], name: "index_purchases_on_warehouse_id"
  end

  create_table "register_sessions", force: :cascade do |t|
    t.bigint "register_id", null: false
    t.bigint "opened_by_id", null: false
    t.bigint "closed_by_id"
    t.datetime "opened_at", null: false
    t.decimal "opening_balance", precision: 10, scale: 2, null: false
    t.text "opening_notes"
    t.datetime "closed_at"
    t.decimal "closing_balance", precision: 10, scale: 2
    t.decimal "expected_balance", precision: 10, scale: 2
    t.decimal "difference", precision: 10, scale: 2
    t.text "closing_notes"
    t.decimal "total_sales", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_cash_sales", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_card_sales", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_credit_sales", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "sales_count", default: 0, null: false
    t.integer "cancelled_sales_count", default: 0, null: false
    t.decimal "cancelled_sales_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "total_inflows", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_outflows", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["closed_by_id"], name: "index_register_sessions_on_closed_by_id"
    t.index ["opened_at"], name: "index_register_sessions_on_opened_at"
    t.index ["opened_by_id"], name: "index_register_sessions_on_opened_by_id"
    t.index ["register_id", "closed_at"], name: "index_register_sessions_on_register_id_and_closed_at"
    t.index ["register_id"], name: "index_register_sessions_on_register_id"
    t.index ["status"], name: "index_register_sessions_on_status"
    t.index ["total_inflows"], name: "index_register_sessions_on_total_inflows"
    t.index ["total_outflows"], name: "index_register_sessions_on_total_outflows"
  end

  create_table "registers", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "initial_balance", precision: 10, scale: 2, default: "0.0", null: false
    t.string "location"
    t.bigint "warehouse_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_registers_on_active"
    t.index ["code"], name: "index_registers_on_code", unique: true
    t.index ["warehouse_id", "active"], name: "index_registers_on_warehouse_id_and_active"
    t.index ["warehouse_id"], name: "index_registers_on_warehouse_id"
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
    t.decimal "pending_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "register_session_id"
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.text "cancellation_reason"
    t.index ["cancelled_at"], name: "index_sales_on_cancelled_at"
    t.index ["cancelled_by_id"], name: "index_sales_on_cancelled_by_id"
    t.index ["customer_id", "payment_status"], name: "index_sales_on_customer_id_and_payment_status", where: "(pending_amount > (0)::numeric)"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["payment_status"], name: "index_sales_on_payment_status"
    t.index ["register_session_id", "status"], name: "index_sales_on_register_session_id_and_status"
    t.index ["register_session_id"], name: "index_sales_on_register_session_id"
    t.index ["sale_date"], name: "index_sales_on_sale_date"
    t.index ["status", "sale_date"], name: "index_sales_on_status_and_sale_date"
    t.index ["status"], name: "index_sales_on_status"
    t.index ["user_id"], name: "index_sales_on_user_id"
    t.index ["warehouse_id"], name: "index_sales_on_warehouse_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "phone"
    t.string "mobile"
    t.string "rfc"
    t.string "company_name"
    t.text "address"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.boolean "active", default: true, null: false
    t.text "notes"
    t.index ["active"], name: "index_suppliers_on_active"
    t.index ["email"], name: "index_suppliers_on_email"
    t.index ["name"], name: "index_suppliers_on_name"
    t.index ["rfc"], name: "index_suppliers_on_rfc"
  end

  create_table "units", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "name", null: false
    t.integer "role", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "barcodes", "products"
  add_foreign_key "cash_register_flows", "register_sessions"
  add_foreign_key "cash_register_flows", "users", column: "authorized_by_id"
  add_foreign_key "cash_register_flows", "users", column: "cancelled_by_id"
  add_foreign_key "cash_register_flows", "users", column: "created_by_id"
  add_foreign_key "inventories", "products"
  add_foreign_key "inventories", "warehouses"
  add_foreign_key "inventory_adjustments", "inventories"
  add_foreign_key "inventory_adjustments", "users", column: "performed_by_id"
  add_foreign_key "inventory_movements", "inventories"
  add_foreign_key "payment_applications", "payments"
  add_foreign_key "payment_applications", "sales"
  add_foreign_key "payments", "customers"
  add_foreign_key "payments", "sales"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "products", column: "master_product_id", on_delete: :restrict
  add_foreign_key "products", "units", column: "purchase_unit_id"
  add_foreign_key "products", "units", column: "sale_unit_id"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "purchases", "warehouses"
  add_foreign_key "register_sessions", "registers"
  add_foreign_key "register_sessions", "users", column: "closed_by_id"
  add_foreign_key "register_sessions", "users", column: "opened_by_id"
  add_foreign_key "registers", "warehouses"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "register_sessions"
  add_foreign_key "sales", "users", column: "cancelled_by_id"
  add_foreign_key "sales", "warehouses"
end
