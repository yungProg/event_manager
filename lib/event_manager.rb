require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
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

def peak_hours(dates)
    hours_arr = dates.map do |date|
        Time.strptime(date, '%m/%d/%y %H:%M').hour.to_s + ':00'
    end
    hours_arr.sort!
    hours_arr = hours_arr.group_by(&:itself).values
    hours_template = File.read('registration_hours.erb')
    erb_hours_template = ERB.new hours_template
    tem = erb_hours_template.result(binding)
    File.open('peak_hours.html', 'w') do |file|
      file.puts tem
    end
end

def active_days(dates)
    days_of_week = %[Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday]
    days_arr = dates.map do |date|
        formatted_date = Time.strptime(date, '%m/%d/%y').to_s
        Time.new(formatted_date).strftime('%A')
    end
    days_arr = days_arr.group_by(&:itself).values
    days_arr.sort_by! {|day| days_of_week.index(day.first)}
    days_template = File.read('registration_days.erb')
    erb_days_template = ERB.new days_template
    tem = erb_days_template.result(binding)
    File.open('active_days.html', 'w') do |file|
        file.puts tem
    end
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

peak_hours(reg_dates)
active_days(reg_dates)