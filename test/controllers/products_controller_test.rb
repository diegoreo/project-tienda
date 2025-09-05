require "test_helper"
class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @warehouse = warehouses(:one)
  end

  test "render a list of products" do
    get products_path

    assert_response :success
    assert_select ".product", 5
    assert_select ".category",8
  end

  test "render a list of products filtered by category" do
    get products_path(category_id: categories(:bebidas).id)

    assert_response :success
    assert_select ".product", 1
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
      assert_equal flash[:notice], "Producto creado con exito."
    end



    test "does not allow to create a new product with empty fields" do
      post products_path, params: {
        product: {
          name: "",
          description: "Refresco sabor cola en botella de 355ml",
          price: 13.00,
          stock_quantity: 2,
          purchase_unit_id: units(:caja).id,
          sale_unit_id: units(:pieza).id,
          unit_conversion: 24,
          category_id: categories(:bebidas).id
        }
      }

      assert_response :unprocessable_content 
    end

    test "render an edit product form" do
      get edit_product_path(products(:coca_cola))

      assert_response :success
      assert_select "form"
    end

    test "allow to update a product" do
      patch product_path(products(:coca_cola)), params: {
        product: {
          price: 14.00
        }
      }

      assert_redirected_to products_path
      assert_equal flash[:notice], "Tu producto se ha actualizado correctamnete"
    end

    test "does not allow to update a product with an invalid field" do
      patch product_path(products(:coca_cola)), params: {
        product: {
          price: nil
        }
      }

      assert_response :unprocessable_content 
    end

    test "can delete products" do
      assert_difference("Product.count", -1) do
        delete product_path(products(:producto_libre))
      end
      assert_redirected_to products_path
      assert_equal flash[:notice], "El producto se elimino correctamente"
    end
    
end