module Em
  module Zimbreasy
    class Mail
      include Icalendar
      attr_accessor :account, :zimbra_namespace

      def initialize(account)
        @account = account
        @zimbra_namespace = "urn:zimbraMail"
      end

      #Params can contain the following:
      #:appointee_emails(req)
      #:start_time(opt)
      #:end_time(opt)
      #:name(opt)
      #:subject(opt)
      #:desc(opt)
      #:mime_type(opt)
      #Returns Appt's Inv id as UID in an i_cal text.. Is normally a number like 140-141,
      #the first number is the appt id, which you need for getting.
      def create_appointment(params)
        params[:start_time] = Em::Zimbreasy.zimbra_date(params[:start_time]) if params[:start_time]
        params[:end_time] = Em::Zimbreasy.zimbra_date(params[:end_time]) if params[:end_time]

        response = account.make_call(
          :CreateAppointmentRequest, 
          { "xmlns" => @zimbra_namespace, "echo" => (params[:echo] || "0")},
          appointment_hash(params)
        ) 

        params.merge!({:appt_id => response.body[:create_appointment_response][:@inv_id]})

        to_ical(params)
      end

      def get_free_busy(start_time, end_time, email)
        start_time = start_time.to_i*1000 #it wants millis, to_i gives seconds.
        end_time = end_time.to_i*1000

        response = account.make_call(
          :GetFreeBusyRequest,
          {:xmlns => @zimbra_namespace, :s => start_time, :e => end_time},
          { :usr => { :name => email }}
        )
   
        array = [] 
        return response[:get_free_busy_response][:usr].reject { |k,v| k if k == :@id }.inject(Hash.new) do |hash, entry|
          if entry[1].is_a?(Array)
            array_of_times = entry[1].inject(Array.new) do |times_array, times_entry|
              times_array << { :s => Time.at(times_entry[:@s].to_f/1000.0), :e => Time.at(times_entry[:@e].to_f/1000.0) }
              times_array
            end
            hash[entry[0]] = array_of_times 
          else
            hash[entry[0]] = [ {:s => Time.at(entry[1][:@s].to_f/1000.0), :e => Time.at(entry[1][:@e].to_f/1000.0)} ] 
          end
          hash 
        end
      end
   
      def get_appointment(appt_id)

        response = account.make_call(
          :GetAppointmentRequest,
          { :xmlns => @zimbra_namespace, :id => appt_id},
          {}
        )

        comp = response[:get_appointment_response][:appt][:inv][:comp]

        hash = {
          :start_time => comp[:s][:@d], 
          :end_time => comp[:e][:@d], 
          :desc => comp[:desc],  
          :name => comp[:@name],
          :appt_id => appt_id
        }

        to_ical(hash)
      end 

      def get_appt_summaries(start_date, end_date)
        start_date = start_date.to_i*1000 #it wants millis, to_i gives seconds.
        end_date = end_date.to_i*1000

        response = account.make_call(
          :GetApptSummariesRequest,
          { :xmlns => @zimbra_namespace, :e => end_date, :s => start_date},
          {}
        )

        return [] if response[:get_appt_summaries_response][:appt].nil?

        appts = []

        if response[:get_appt_summaries_response][:appt].is_a?(Array)
          response[:get_appt_summaries_response][:appt].each do |appt|
            
            inst = appt[:inst]
                      
            hash = {
              :start_time => Em::Zimbreasy.zimbra_date(Time.at(inst[:@s].to_f/1000.0)), 
              :name => appt[:@name], 
              :appt_id => appt[:@id]
            }

            appts << to_ical(hash)
          end
        else 
          appt = response[:get_appt_summaries_response][:appt]

          inst = appt[:inst]

          hash = {
            :start_time => Zimbreasy.zimbra_date(Time.at(inst[:@s].to_f/1000.0)),
            :name => appt[:@name],
            :appt_id => appt[:@id]
          }

          appts << to_ical(hash)
        end
        
        appts
      end 

      #same param options as create_appointment, but you can add :inv_id too.
      def modify_appointment(params)
        params[:start_time] = Em::Zimbreasy.zimbra_date(params[:start_time]) if params[:start_time]
        params[:end_time] = Em::Zimbreasy.zimbra_date(params[:end_time]) if params[:end_time]

        response = account.make_call(
          :ModifyAppointmentRequest,
          { :xmlns => @zimbra_namespace, :id => params[:inv_id]},
          appointment_hash(params)
        )
      
        to_ical(params.merge({:appt_id => params[:inv_id]}))
      end

      #returns true if it worked, inv_id is not appt_id, it's normally something like 320-319, the first number is appt_id.
      def cancel_appointment(inv_id, emails, subject=nil, content=nil)
        unless inv_id and inv_id.is_a?(String) and inv_id.match(/-/) and inv_id.split("-").count==2 #so it has x-y formatting.
          raise 'inv_id must be string of format x-y, where x and y are numbers.'
        end

        message = {
          :m => {
            :su => subject,
            :mp => {
              :content => content
              :attributes! => { :ct => "text/plain" }                
            }
          }
        }

        message[:m][:e] = []
        emails.each do |email|
          message[:m][:e].push({ :a => email, :t => "t" })
        end

        response = account.make_call(
          :CancelAppointmentRequest,
          { :xmlns => @zimbra_namespace, :id => inv_id, :comp => 0},
          message
        )        

        return !response.body[:cancel_appointment_response].nil?
      end

      private

      def to_ical(params)
        calendar = Calendar.new   
        calendar.event do
          dtstart       params[:start_time]
          dtend         params[:end_time]
          summary       params[:name]
          description   params[:desc]
          uid           params[:appt_id]
          klass         "PRIVATE"  
        end
        calendar.to_ical
      end

      def appointment_hash(params)
        message = {
          :m => {
            :mp => { :ct => (params[:mime_type] || "text/plain") },
            :inv => {
              :mp => { :ct =>(params[:mime_type] || "text/plain") },
              :desc => params[:desc],
              :attributes! => { :rsvp => "1", :compNum => "0", :method => "none", :name => params[:name]  }
            },
            :attributes! => { :su => params[:subject] }
          }
        }

        message[:m][:inv][:s] = { :d => params[:start_time],  :tz => params[:tz] } if params[:start_time]
        message[:m][:inv][:s] = { :d => params[:end_time],    :tz => params[:tz] } if params[:end_time]
        mesage[:m][:e] = []
        params[:appointee_emails].each do |email| 
          message[:m][:e].push({ :a => email, :t => "t" })
        end
        return message
      end

    end
  end
end
