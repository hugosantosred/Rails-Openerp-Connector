require File.dirname(__FILE__) + '/../../test_helper'

# Re-raise errors caught by the controller.
Admin::ExternalFieldReferentialController.class_eval { def rescue_action(e) raise e end }

class Admin::ExternalFieldReferentialControllerTest < ActionController::TestCase

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
