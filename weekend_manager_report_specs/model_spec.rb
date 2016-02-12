require 'spec_helper'

describe "WeekendManagerReport" do

	before :all do
		@user = FactoryGirl.create(:user)
		@user.access_permissions.build(:name => "wmr")
    @user.save
	end

  after :all do
    @user.destroy
  end

	describe "Validations: " do
		before :each do
  		@report = FactoryGirl.build(:weekend_manager_report, :creator_id => @user.id)
  	end

		it "correctly fails presence/inclusion validations" do
			["facility_id", "date", "name", "clinical_manager", "nighttime_supervisor", "therapist", "dietary_supervisor", "friday_initial_census", "friday_net_census", "saturday_net_census", "sunday_net_census"].each do |field|
				@report.valid?
				@report.errors.keys.should_not include(field.to_sym)
				@report.send(field + "=", nil)
				@report.valid?
				@report.errors.keys.should include(field.to_sym)
			end
		end

	end

  describe "Testing Current Reports scope: " do

  	before :each do
  		@report = FactoryGirl.create(:weekend_manager_report, :creator_id => @user.id)
  	end

	  after :each do
	    @report.destroy
	  end

  	it "Expects new report to be included in current_reports" do
	  	expect(WeekendManagerReport.current_reports(@user)).to include(@report)
	  end

	  it "Expects submitted new report not to be included in current_reports" do
	  	@report.submit
	  	expect(WeekendManagerReport.current_reports(@user)).not_to include(@report)
		end

  end
end
