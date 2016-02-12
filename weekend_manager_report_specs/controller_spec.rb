require 'spec_helper'

describe WeekendManagerReportsController, :type => :controller do

  create_user_and_add_login_hooks(["wmr"])
  # copied from helper file
  # def create_user_and_add_login_hooks(permissions = ["admin"], user_variable_name = "user")

  #   before :all do
  #     u = FactoryGirl.create(:user)
  #     permissions.each do |permission|
  #       u.access_permissions.build(:name => permission)
  #     end
  #     u.save
  #     instance_variable_set("@"+user_variable_name, u)
  #   end

  #   after :all do
  #     u = instance_variable_get("@"+user_variable_name)
  #     u.destroy
  #   end

  #   before :each do
  #     u = instance_variable_get("@"+user_variable_name)
  #     sign_in u
  #   end

  #   let(:valid_session) { {:user_id => instance_variable_get("@"+user_variable_name).id }}

  # end
  
  let(:valid_attributes) {
    FactoryGirl.nested_attr(:weekend_manager_report, :creator_id => @user.id)
  }

  let(:invalid_attributes) { {:creator_id => nil} }


  describe "GET Index" do

    it "Assigns :current_reports includes newly created report" do
      wmr = FactoryGirl.create(:weekend_manager_report, :creator_id => @user.id)
      get :index
      expect(assigns(:current_reports)).to include(wmr)
    end

  end


  describe "New WeekendManagerReport" do

    it "redirects to confirm_new if current report exists" do
      post :create, {:weekend_manager_report => valid_attributes}, valid_session
      get :new, {}, valid_session
      expect(response).to redirect_to(confirm_new_weekend_manager_report_path)
    end

    it "forwards to new WMR form if confirm_new param is set" do
      post :create, {:weekend_manager_report => valid_attributes}, valid_session
      get :new, {:confirm_new => true}, valid_session
      expect(response).to render_template(:new)
    end

  end

  describe "Create WeekendManagerReport" do

    describe "With valid attributes" do

      # it "saves report with  same attributes as what it was created with" do
      #   post :create, {:weekend_manager_report => valid_attributes}, valid_session
      #   w = WeekendManagerReport.eager_load( :admissions, :discharges, :wmr_resident_family_concerns, :wmr_therapy_concerns, :wmr_pharmacy_concerns, :wmr_general_center_concerns, :employee_call_offs, :admission_inquiries, ).last
      #   w.should reflect_supplied_attributes(valid_attributes)
      #   # reflect_supplied_attributes is a custom matcher: 
      # end

      it "weekend_manager_report_params contains all parameters passed to it" do
        post :create, {:weekend_manager_report => valid_attributes}, valid_session

        # loop through each attribute in valid_attributes
        valid_attributes.each do |name, value|
          if value.is_a?(Array) # handle if it's a list of has_many's (Admission, Discharge, NurseShift, etc)
            value.each_with_index do |has_many, i|
              # loop through the attributes of the has_many, compare like below
              has_many.each do |has_many_name, has_many_value|
                controller.send(:weekend_manager_report_params)[name][i].should have_key(has_many_name.to_sym)
                controller.send(:weekend_manager_report_params)[name][i][has_many_name.to_sym].to_s.should eq(has_many_value.to_s)
              end
            end
          elsif value.is_a?(Hash) # a has_one, checklist for example
            value.each do |has_one_name, has_one_value|
              controller.send(:weekend_manager_report_params)[name].should have_key(has_one_name.to_sym)
              controller.send(:weekend_manager_report_params)[name][has_one_name.to_sym].to_s.should eq(has_one_value.to_s)
            end
          else # compare presence and value of param and valid_attributes value
            controller.send(:weekend_manager_report_params).should have_key(name.to_sym)
            controller.send(:weekend_manager_report_params)[name.to_sym].to_s.should eq(value.to_s)
          end
        end

      end

      it "creates a new WeekendManagerReport" do
        expect {
          post :create, {:weekend_manager_report => valid_attributes}, valid_session
        }.to change(WeekendManagerReport, :count).by(1)
      end

      it "is not valid with an invalid parameter" do
        post :create, {:weekend_manager_report => valid_attributes}, valid_session
        w = WeekendManagerReport.last
        w.should be_valid

        w.destroy
      end

      it "redirects to the created WeekendManagerReport" do
        post :create, {:weekend_manager_report => valid_attributes}, valid_session
        response.should redirect_to(WeekendManagerReport.last)
      end

      it "loads WMR show page correctly" do
        post :create, {:weekend_manager_report => valid_attributes}, valid_session
        get :show, id: WeekendManagerReport.last.id
        response.should render_template("reports/show.html")
        response.status.should be(200)
      end
    end

    describe "with invalid attributes" do
      it "re-renders the 'new' template" do
        WeekendManagerReport.any_instance.stub(:save).and_return(false)
        post :create, {:weekend_manager_report => invalid_attributes}, valid_session
        response.should render_template("new")
      end
    end

  end

  describe "Update WeekendManagerReport" do
    describe "with valid params" do
      it "redirects to the WeekendManagerReport" do
        weekend_manager_report = FactoryGirl.create(:weekend_manager_report)
        put :update, {:id => weekend_manager_report.to_param, :weekend_manager_report => valid_attributes}, valid_session
        response.should redirect_to(weekend_manager_report)
      end
    end

    describe "with invalid params" do
      it "re-renders the 'edit' template" do
        weekend_manager_report = FactoryGirl.create(:weekend_manager_report)
        # Trigger the behavior that occurs when invalid params are submitted
        WeekendManagerReport.any_instance.stub(:save).and_return(false)
        put :update, {:id => weekend_manager_report.to_param, :weekend_manager_report => invalid_attributes}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "Delete weekend_manager_report" do
    it "destroys the requested weekend_manager_report" do
      weekend_manager_report = FactoryGirl.create(:weekend_manager_report)
      expect {
        delete :destroy, {:id => weekend_manager_report.to_param}, valid_session
      }.to change(WeekendManagerReport, :count).by(-1)
    end

    it "redirects to the weekend_manager_reports list" do
      weekend_manager_report = FactoryGirl.create(:weekend_manager_report)
      delete :destroy, {:id => weekend_manager_report.to_param}, valid_session
      response.should redirect_to(weekend_manager_reports_url)
    end
  end

end
