require "test_helper"
class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "render a list of categories" do
    get categories_path

    assert_response :success
    assert_select ".category-card",8
  
  end

  test "render a new category form" do
    get new_category_path

    assert_response :success
    assert_select "form"
  end

  test "allow to create a new category" do
    post categories_path, params: {
      category: {
        name: "Otros",
        description: "Productos poco usuales"
      }
    }

    assert_redirected_to categories_path
    assert_equal flash[:notice], "Tu categoria se creo correctamente!"
  end

  test "does not allow to create a new category with empty fields" do
    post categories_path, params: {
      category: {
        name: "",
        description: "Productos poco usuales"
      }
    }

    assert_response :unprocessable_content 
  end

  test "render an edit category form" do
    get edit_category_path(categories(:bebidas))

    assert_response :success
    assert_select "form"
  end

  test "allow to update a category" do
    patch category_path(categories(:bebidas)), params: {
      category: {
        name: "Bebida"
      }
    }

    assert_redirected_to categories_path
    assert_equal flash[:notice], "tu categoria se actualizo correctamente"
  end

  test "does not allow to update a category with an invalid field" do
    patch category_path(categories(:bebidas)), params: {
      category: {
        name: ""
      }
    }

    assert_response :unprocessable_content 
  end

  test "can delete cateories" do
    assert_difference("Category.count", -1) do
      delete category_path(categories(:articulos_limpieza))
    end
    assert_redirected_to categories_path
    assert_equal flash[:notice], "La categoria se elimino correctamente"

  end
end