require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
    number_string = phone_number.to_s
    number_of_digits = number_string.scan(/\d/).size
    
    if number_of_digits == 10
        phone_number
    elsif number_of_digits[0] == 1 && number_of_digits == 11
        phone_number.delete_prefix('1')
    else
        'Invalid phone number'
    end
end

def most_active_date(dates)
    dates_str = dates.map do |date|
        date = date.to_s
        Date.parse(date).to_s
    end
    dates_str
    #dates.group_by(&:itself).values.max_by(&:size).first
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        civic_info.representative_info_by_address(
            address: zipcode,
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

    File.open(filename, 'w') do | file |
      file.puts form_letter
    end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol    
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
reg_dates = []

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    reg_dates.push(row[:regdate])

    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode(zipcode)

    phone_number = clean_phone_number(row[:homephone])

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id,form_letter)
end

# a = ['11/12/08 10:47', '11/12/08 13:23', '11/12/08 13:30']
# # a.map do |bs|
# #     p Date.parse(bs).to_s
# # end

p most_active_date(reg_dates)