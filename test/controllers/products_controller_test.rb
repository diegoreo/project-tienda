require "test_helper"
class ProductsControllerTest < ActionDispatch::IntegrationTest


  test "render a list of products" do
    get products_path

    assert_response :success
    assert_select ".product", 4
  
  end


    test "render a detailed product page" do
      get product_path(products(:coca_cola))
  
      assert_response :success
      assert_select ".name", "CocaCola 600ml"
      assert_select ".description", "Descripción: Refresco sabor cola en botella de 600ml"
      assert_select ".price", "Precio: $20.00"
    end

    test "render a new product form" do
      get new_product_path

      assert_response :success
      assert_select "form"
    end

    test "allow to create a new product" do
      post products_path, params: {
        product: {
          name: "CocaCola 355ml",
          description: "Refresco sabor cola en botella de 355ml",
          price: 13.00,
          stock_quantity: 2,
          purchase_unit_id: units(:caja).id,
          sale_unit_id: units(:pieza).id,
          unit_conversion: 24,
          category_id: categories(:bebidas).id
        }
      }

      assert_redirected_to products_path
    end
end