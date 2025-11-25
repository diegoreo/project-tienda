require "test_helper"
class UnitsControllerTest < ActionDispatch::IntegrationTest
  test "render a list of units" do
    get units_path

    assert_response :success
    assert_select ".unit-card", 6
  end

  test "render a new category form" do
    get new_unit_path

    assert_response :success
    assert_select "form"
  end

  test "allow to create a new unit" do
    post units_path, params: {
      unit: {
        name: "Gramo",
        abbreviation: "gr",
        description: "Unidad de peso gramos, cuando se compra en kilo unidad de venta podria ser gramo"
      }
    }

    assert_redirected_to units_path
    assert_equal flash[:notice], "Tu unidad de medida se creo correctamente!"
  end

  test "does not allow to create a new unit with empty fields" do
    post units_path, params: {
      unit: {
        name: "",
        abbreviation: "gr",
        description: "Unidad de peso gramos, cuando se compra en kilo unidad de venta podria ser gramo"
      }
    }

    assert_response :unprocessable_content
  end

  test "render an edit unit form" do
    get edit_unit_path(units(:caja))

    assert_response :success
    assert_select "form"
  end

  test "allow to update a unit" do
    patch unit_path(units(:paquete)), params: {
      unit: {
        description: "Conjunto de varias piezas empaquetadas t"
      }
    }

    assert_redirected_to units_path
    assert_equal flash[:notice], "tu unidad de medida se actualizo correctamente"
  end

  test "does not allow to update a unit with an invalid field" do
    patch unit_path(units(:caja)), params: {
      unit: {
        name: ""
      }
    }

    assert_response :unprocessable_content
  end

  test "can delete units" do
    assert_difference("Unit.count", -1) do
      delete unit_path(units(:litro))
    end
    assert_redirected_to units_path
    assert_equal flash[:notice], "La unidad de medida se elimino correctamente"
  end
end
