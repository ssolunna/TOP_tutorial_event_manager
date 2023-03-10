require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  
  phonenumber = row[:homephone].split(//)
  phonenumber = phonenumber.filter { |char| char.match?(/[0-9]/) }.join
  # if phone number is less than 10 digits, is a bad number
  if phonenumber.length < 10
    phonenumber = "Invalid phone number"
  # if phone number is 10 digits, is a good number
  elsif phonenumber.length == 10
    phonenumber
  # if phone number is 11 digits and the first number is 1, trim the 1and use the remaining 10 digits
  elsif phonenumber.length == 11 && phonenumber.start_with?("1")
    phonenumber = phonenumber[1..-1]
  # if phone number is 11 digits and the first number is not 1, is a bad number
  # if phone number is more than 11 digits, is a bad number
  elsif phonenumber.length >= 11
    phonenumber = "Invalid phone number"
  end

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end
