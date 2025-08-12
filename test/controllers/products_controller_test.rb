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
end