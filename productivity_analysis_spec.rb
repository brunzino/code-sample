# To save time, exclude tests that import the full dataset
# rspec spec/ams_reports/productivity_analysis_spec.rb -t ~full_import

require 'rails_helper'

describe "Productivity Analysis" do 

	let(:pa) do 
		pa = AMSReports::ProductivityAnalysis.new 
		# manually set headings so import is not needed
		pa.headings = ["reportID", "userID", "lastEditBy", "lastEditDate", "lastOpenDate", "reportDate", "clientCaseNumber", "serviceSuffix", "clientCaseService", "billType", "serviceCode", "isBillable", "placeofService", "modifier", "minorityCode", "titleXXRecipient", "pMeetings", "pTraining", "pSupervision", "pTravel", "pTotal", "cFaceToFace", "cTelephone", "cCollateralTelephone", "cCollateralFacetoFace", "cGroup", "cDocumentation", "cCollaboration", "cTotal", "cNumMiles", "cMinutes", "cOneWay", "cUnits", "cFee", "cFaceToFace_NB", "cTelephone_NB", "cCollateralTelephone_NB", "cCollateralFacetoFace_NB", "cGroup_NB", "cDocumentation_NB", "cCollaboration_NB", "cTotal_NB", "cNumMiles_NB", "cMinutes_NB", "cOneWay_NB", "cUnits_NB", "cFee_NB", "Comments", "dontCredit", "refNumber", "groupRef", "appointmentID", "clockin", "clockout", "officelocation", "destination", "ledgerID", "currFee", "typeOfService", "serviceProvided", "flag", "Expr1", "Expr2"] 
		return pa
	end

	let(:sample_row) do 
		row = Array.new(63).fill(0)
		row[0] = 536630
		row[1] = "arehl" 
		row[5] = Date.today - 1.month
		return row
	end


	it "exists" do 
		expect(pa).to be_a(AMSReports::ProductivityAnalysis)
	end

	it "pa has correct headings (quickly for testing purposes)", :meta => true do 
		pa.import_initialize("arehl.xls")
		expect(pa.headings).to eq(pa.get_headings)
	end

	describe "Retrieving labels", :labels => true do 
		
		# as defined in AMSReports::ProductivityAnalysis
		let(:non_existent_label) { "[No label matches this field]" }

		it "returns non-existent label for non-existing column" do 
			expect(pa.label("non_existent")).to eq(non_existent_label)
		end

		it "returns correct label for existing label" do
			expect(pa.label).to eq(non_existent_label)
			expect(pa.label("pMeetings")).to eq("Mental Health Assessment")
		end

		it "returns labels for all existing columns" do 
			pa.columns_to_count_incidents.each do |heading|
				expect(pa.label(heading)).to_not eq(non_existent_label)
			end
			pa.columns_to_count_hours.each do |heading|
				expect(pa.label(heading)).to_not eq(non_existent_label)
			end
			pa.extra_columns_to_track.each do |heading|
				expect(pa.label(heading)).to_not eq(non_existent_label)
			end
		end
	end

	describe "Subject Schema", :subject_schema => true do 
		it "subject schema has all required fields for each subject" do 
			schema = pa.get_subject_schema
			schema.each do |subject|
				expect(subject["name"]).to_not be nil
				expect(subject["userID"]).to_not be nil 
				expect(subject["expected_hours"]).to_not be nil 
			end
		end

		it "correctly returns subject field" do 
		  expect(pa.get_subject_field("bdalesio", "name")).to eq("Becky D'Alesio")
		end
	end


	it "correctly calculates users' available hours as (expected_hours - pTravel)", :get_user_available_hours => true do 
		pa.clear_db_table
		
		column = "pTravel" 
		sample_row[19] = 10
		pa.import_cell(sample_row, column)
		
		sample_row[19] = 5
		pa.import_cell(sample_row, column)

		# arehl expected_hours is 150, the rows above combine to 15, so available hours should = expected - 15
		expect(pa.get_user_available_hours("arehl")).to eq(pa.get_subject_field("arehl", "expected_hours") - 15)
	end


	describe "Getting and manipulating cell values correctly", :get_cell_value => true do 
		it "correctly grabs cell value from officelocation_in row" do 
			sample_row[54] = "in"
			column = "officelocation_in"
			expect(pa.get_cell_value(sample_row, column)).to eq(1)
		end
		it "correctly grabs cell value from officelocation_out row" do 
			sample_row[54] = "out"
			column = "officelocation_out"
			expect(pa.get_cell_value(sample_row, column)).to eq(1)
		end
		it "correctly grabs cell value from officelocation_total row for 'in'" do 
			sample_row[54] = "in"
			column = "officelocation_total"
			expect(pa.get_cell_value(sample_row, column)).to eq(1)
		end
		it "correctly grabs cell value from officelocation_total row for 'out'" do 
			sample_row[54] = "out"
			column = "officelocation_total"
			expect(pa.get_cell_value(sample_row, column)).to eq(1)
		end
		it "correctly grabs cell value from officelocation_total row for 'out'" do 
			sample_row[54] = ""
			column = "officelocation_total"
			expect(pa.get_cell_value(sample_row, column)).to eq(nil)
		end
		it "correctly grabs cell value from Cancellation row" do 
			sample_row[54] = "in"
			column = "officelocation_in"
			expect(pa.get_cell_value(sample_row, column)).to eq(1)
		end
		it "correctly grabs 0 cell value from Cancellation row" do 
			sample_row[6] = 0
			column = "clientCaseNumber" 
			expect(pa.get_cell_value(sample_row, column)).to eq(nil)
		end
	end


	it "correctly counts distinct Client Case Numbers", :get_column_unique => true do 
		pa.clear_db_table

		expect {
			sample_row[6] = 45811
			column = "clientCaseNumber" 
			pa.import_cell(sample_row, column)

			sample_row[6] = 45811
			column = "clientCaseNumber" 
			pa.import_cell(sample_row, column)

			sample_row[6] = 45812
			column = "clientCaseNumber" 
			pa.import_cell(sample_row, column)

			sample_row[6] = 45813
			column = "clientCaseNumber" 
			pa.import_cell(sample_row, column)

			sample_row[6] = 0
			column = "clientCaseNumber" 
			pa.import_cell(sample_row, column)		
    }.to change{AMSReports::ProductivityAnalyses::DataCell.count}.by(4)

		expect(pa.get_column_unique("arehl", "clientCaseNumber")).to eq(3)
	end






	describe "Correct Importing", :import_cell => true do 

		before(:each) do 
			pa = AMSReports::ProductivityAnalysis.new
			pa.clear_db_table 
		end

		it "correctly imports a cell (simple)" do 
			sample_row[16] = 1.33
			column = "pMeetings" 
			expect{
				pa.import_cell(sample_row, column)
			}.to change{AMSReports::ProductivityAnalyses::DataCell.count}.by(1)
			new_row = AMSReports::ProductivityAnalyses::DataCell.last
			expect(new_row.reportID).to eq(sample_row[0])
			expect(new_row.userID).to eq(sample_row[1])
			expect(new_row.heading).to eq(column)
			expect(new_row.report_date).to eq(sample_row[5])
			expect(new_row.value).to eq(sample_row[16])
		end


		it "correctly imports an officelocation_in cell" do 
			sample_row[54] = "in"
			column = "officelocation_in" 
			expect{
				pa.import_cell(sample_row, column)
			}.to change{AMSReports::ProductivityAnalyses::DataCell.count}.by(1)
			new_row = AMSReports::ProductivityAnalyses::DataCell.last
			expect(new_row.heading).to eq("officelocation_in")
			expect(new_row.value).to eq(1)
		end	

		it "correctly imports an officelocation_out cell" do 
			sample_row[54] = "out"
			column = "officelocation_out" 
			expect{
				pa.import_cell(sample_row, column)
			}.to change{AMSReports::ProductivityAnalyses::DataCell.count}.by(1)
			new_row = AMSReports::ProductivityAnalyses::DataCell.last
			expect(new_row.heading).to eq("officelocation_out")
			expect(new_row.value).to eq(1)
		end	

		it "correctly imports an officelocation_out cell, disregards if cancellation" do 
			sample_row[54] = "out"
			sample_row[45] = 1
			column = "officelocation_out" 
			expect{
				pa.import_cell(sample_row, column)
			}.to change{AMSReports::ProductivityAnalyses::DataCell.count}.by(0)
		end	

		it "correctly imports an officelocation_out cell, disregards if cancellation" do 
			sample_row[54] = "out"
			sample_row[46] = 1
			column = "officelocation_out" 
			expect{
				pa.import_cell(sample_row, column)
			}.to change{AMSReports::ProductivityAnalyses::DataCell.count}.by(0)
		end	

		it "correctly imports a Cancellation (Total) cell" do 
			sample_row[46] = 1
			column = "cFee_NB_total" 
			expect{
				pa.import_cell(sample_row, column)
			}.to change{AMSReports::ProductivityAnalyses::DataCell.count}.by(1)
			new_row = AMSReports::ProductivityAnalyses::DataCell.last
			expect(new_row.heading).to eq("cFee_NB_total")
			expect(new_row.value).to eq(1)
		end	

		it "correctly imports a Cancellation (Late) cell" do 
			sample_row[46] = 2
			column = "cFee_NB_late" 
			expect{
				pa.import_cell(sample_row, column)
			}.to change{AMSReports::ProductivityAnalyses::DataCell.count}.by(1)
			new_row = AMSReports::ProductivityAnalyses::DataCell.last
			expect(new_row.heading).to eq("cFee_NB_late")
			expect(new_row.value).to eq(1)
		end	

		it "correctly imports a Client Case Number" do 
			sample_row[6] = 45811
			column = "clientCaseNumber" 
			expect{
				pa.import_cell(sample_row, column)
			}.to change{AMSReports::ProductivityAnalyses::DataCell.count}.by(1)
			new_row = AMSReports::ProductivityAnalyses::DataCell.last
			expect(new_row.heading).to eq("clientCaseNumber")
			expect(new_row.value).to eq(sample_row[6])
		end	
	end


	it "imports all rows on full import", :full_import => true do 
		pa.clear_db_table
		pa.import_sheet("productivity_analysis_arehl.xls")
		expect(AMSReports::ProductivityAnalyses::DataCell.where(:heading => "pMeetings").count).to eq(125)
	end


	describe "after successful full import", :full_import => true do 

		before :all do 
			pa = AMSReports::ProductivityAnalysis.new
			pa.clear_db_table
			pa.full_import
			# pa.get_data_files.each do |file_stub|
			# 	pa.import_sheet(file_stub)
			# end
		end

		it "judges whether it's time to update correctly" do 
			original_db_import_time = AMSReports::ProductivityAnalyses::DataCell.first.created_at
			
			# if it looks like data cells were all just set now, not ready to update
			AMSReports::ProductivityAnalyses::DataCell.update_all(:created_at => DateTime.now)
			expect(pa.ready_to_update?).to be false

			# set database import time to one month ago
			new_db_update_time = DateTime.now - 1.month
			AMSReports::ProductivityAnalyses::DataCell.update_all(:created_at => new_db_update_time)

			# set file creation time to less than one month ago (so it's newer)
			data_file_fullpaths = pa.get_data_files.map{|f| File.join(pa.class::DATA_PATH, f) }
			data_update_time = Time.now - 10.days
			data_file_fullpaths.each do |file|
				File.utime(data_update_time, data_update_time, file)
			end

			expect(pa.ready_to_update?).to be true

			AMSReports::ProductivityAnalyses::DataCell.update_all(:created_at => original_db_import_time)
		end



		it "correctly calculates a sum and total" do 

	  	start_date = Date.parse("2015-10-01")
			end_date = Date.parse("2015-10-31")

			expect(pa.get_column_sum("arehl", "pMeetings", start_date, end_date)).to eq(11.58)
			expect(pa.get_column_sum("bdalesio", "pMeetings", start_date, end_date)).to eq(21.5)

			total = 0
			pa.columns_to_count_hours.each do |h|
				sum = pa.get_column_sum("bdalesio", h, start_date, end_date)
				# puts "Heading: #{h}, sum: #{sum}"
				total += sum
				# puts "New total: #{total}"
			end

			# puts "Expect total: #{total}"
			# 153.54.to_f + 0.7 = 154.23999999999998 WTF...
			expect(total.round(2)).to eq(pa.get_user_total_hours("bdalesio", start_date, end_date))

		end

	end

end



# Excel_Columns = {
#  "A [0]"=>"reportID",
#  "B [1]"=>"userID",
#  "C [2]"=>"lastEditBy",
#  "D [3]"=>"lastEditDate",
#  "E [4]"=>"lastOpenDate",
#  "F [5]"=>"reportDate",
#  "G [6]"=>"clientCaseNumber",
#  "H [7]"=>"serviceSuffix",
#  "I [8]"=>"clientCaseService",
#  "J [9]"=>"billType",
#  "K [10]"=>"serviceCode",
#  "L [11]"=>"isBillable",
#  "M [12]"=>"placeofService",
#  "N [13]"=>"modifier",
#  "O [14]"=>"minorityCode",
#  "P [15]"=>"titleXXRecipient",
#  "Q [16]"=>"pMeetings",
#  "R [17]"=>"pTraining",
#  "S [18]"=>"pSupervision",
#  "T [19]"=>"pTravel",
#  "U [20]"=>"pTotal",
#  "V [21]"=>"cFaceToFace",
#  "W [22]"=>"cTelephone",
#  "X [23]"=>"cCollateralTelephone",
#  "Y [24]"=>"cCollateralFacetoFace",
#  "Z [25]"=>"cGroup",
#  "AA [26]"=>"cDocumentation",
#  "AB [27]"=>"cCollaboration",
#  "AC [28]"=>"cTotal",
#  "AD [29]"=>"cNumMiles",
#  "AE [30]"=>"cMinutes",
#  "AF [31]"=>"cOneWay",
#  "AG [32]"=>"cUnits",
#  "AH [33]"=>"cFee",
#  "AI [34]"=>"cFaceToFace_NB",
#  "AJ [35]"=>"cTelephone_NB",
#  "AK [36]"=>"cCollateralTelephone_NB",
#  "AL [37]"=>"cCollateralFacetoFace_NB",
#  "AM [38]"=>"cGroup_NB",
#  "AN [39]"=>"cDocumentation_NB",
#  "AO [40]"=>"cCollaboration_NB",
#  "AP [41]"=>"cTotal_NB",
#  "AQ [42]"=>"cNumMiles_NB",
#  "AR [43]"=>"cMinutes_NB",
#  "AS [44]"=>"cOneWay_NB",
#  "AT [45]"=>"cUnits_NB",
#  "AU [46]"=>"cFee_NB",
#  "AV [47]"=>"Comments",
#  "AW [48]"=>"dontCredit",
#  "AX [49]"=>"refNumber",
#  "AY [50]"=>"groupRef",
#  "AZ [51]"=>"appointmentID",
#  "BA [52]"=>"clockin",
#  "BB [53]"=>"clockout",
#  "BC [54]"=>"officelocation",
#  "BD [55]"=>"destination",
#  "BE [56]"=>"ledgerID",
#  "BF [57]"=>"currFee",
#  "BG [58]"=>"typeOfService",
#  "BH [59]"=>"serviceProvided",
#  "BI [60]"=>"flag",
#  "BJ [61]"=>"Expr1",
#  "BK [62]"=>"Expr2"
# }









# headings = 
# ["reportID",
#  "userID",
#  "lastEditBy",
#  "lastEditDate",
#  "lastOpenDate",
#  "reportDate",
#  "clientCaseNumber",
#  "serviceSuffix",
#  "clientCaseService",
#  "billType",
#  "serviceCode",
#  "isBillable",
#  "placeofService",
#  "modifier",
#  "minorityCode",
#  "titleXXRecipient",
#  "pMeetings",
#  "pTraining",
#  "pSupervision",
#  "pTravel",
#  "pTotal",
#  "cFaceToFace",
#  "cTelephone",
#  "cCollateralTelephone",
#  "cCollateralFacetoFace",
#  "cGroup",
#  "cDocumentation",
#  "cCollaboration",
#  "cTotal",
#  "cNumMiles",
#  "cMinutes",
#  "cOneWay",
#  "cUnits",
#  "cFee",
#  "cFaceToFace_NB",
#  "cTelephone_NB",
#  "cCollateralTelephone_NB",
#  "cCollateralFacetoFace_NB",
#  "cGroup_NB",
#  "cDocumentation_NB",
#  "cCollaboration_NB",
#  "cTotal_NB",
#  "cNumMiles_NB",
#  "cMinutes_NB",
#  "cOneWay_NB",
#  "cUnits_NB",
#  "cFee_NB",
#  "Comments",
#  "dontCredit",
#  "refNumber",
#  "groupRef",
#  "appointmentID",
#  "clockin",
#  "clockout",
#  "officelocation",
#  "destination",
#  "ledgerID",
#  "currFee",
#  "typeOfService",
#  "serviceProvided",
#  "flag",
#  "Expr1",
#  "Expr2"]