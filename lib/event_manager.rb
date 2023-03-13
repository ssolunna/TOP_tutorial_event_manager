require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonenumber(phonenumber)
  phonenumber = phonenumber.split(//).filter { |chr| chr.match?(/[0-9]/) }.join

  if phonenumber.length == 10
    phonenumber
  elsif phonenumber.length == 11 && phonenumber.start_with?("1")
    phonenumber[1..-1]
  else
    "Invalid Phone Number"
  end
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

def peak_hours(regdates)
  peak_hours = regdates.reduce(Hash.new(0)) do |list, regdate|
    list[regdate.hour] += 1
    list
  end

  peak_hours.sort_by { |hour, qty| [-qty, hour] }.to_h

  # puts "Peak hours"
  # peak_hours.each { |hour, qty| puts "#{hour.to_s.rjust(2, '0')} Hrs: #{qty}" }
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

regdates = Array.new

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  
  legislators = legislators_by_zipcode(zipcode)
  
  phonenumber = clean_phonenumber(row[:homephone])

  regdates << Time.strptime(row[:regdate], "%m/%d/%y %k:%M") 

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end
