TMail::HeaderField::FNAME_TO_CLASS.delete("content-id")
class NotMultipartMailError < StandardError; end

class MbMpMail
 
  DOMAIN = "example.com"

  attr_reader :html_body, :text_body, :inl_parts, :att_parts

  def initialize(mail)
    raise NotMultipartMailError unless mail.multipart?
    @html_body = ""
    @text_body = ""
    @inl_parts = []
    @att_parts = []

    content_ids = {}
    all_parts(mail) do |part|
      next if part.content_type =~ /^multipart/
      case part.content_type
      when "text/plain"
        @text_body = part.body
      when "text/html"
        @html_body = part.body
      else
        if part["content-id"] then
          before_content_id = part["content-id"].to_s.gsub(/^<|>$/, "")
          content_ids[before_content_id] = generate_content_id
          filename = (part["content-type"]["name"]) ? part["content-type"]["name"] : content_ids[part["content-id"]][/(^[^@]*)@/, 1] + ".#{part.sub_type}"
          inl_part = TMail::Mail.new
          inl_part.content_type = "#{part.content_type}; name=\"#{filename}\""
          inl_part["content-id"] = "<#{content_ids[before_content_id]}>"
          inl_part["content-disposition"] = "inline; filename=\"#{filename}\""
          inl_part.body = [part.body].pack("m")
          inl_part.transfer_encoding = "base64"
          @inl_parts << inl_part
        else
          filename = (part["content-type"]["name"]) ? part["content-type"]["name"] : generate_content_id[/(^[^@]*)@/, 1] + ".#{part.sub_type}"
          att_part = TMail::Mail.new
          att_part.content_type = "#{part.content_type}; name=\"#{filename}\""
          att_part["content-disposition"] = "attachment; filename=\"#{filename}\""
          att_part.body = [part.body].pack("m")
          att_part.transfer_encoding = "base64"
          @att_parts << att_part
        end
      end
    end

    content_ids.each do |before,after|
      @html_body = @html_body.to_s.gsub(/cid:#{before}/, "cid:#{after}")
    end
    @html_body = @html_body.to_s.gsub("\n", "")
  end

  def to_docomo_format
    mail = TMail::Mail.new
    mail.body = ""
    mail.content_type = "multipart/mixed"

    text_part = TMail::Mail.new
    text_part.content_type = "text/plain; charset=\"Shift_JIS\""
    text_part.transfer_encoding = "base64"
    text_part.content_disposition = nil
    text_part.body = [NKF.nkf("-s", @text_body)].pack("m")
    
    unless @html_body.empty? then
      html_part = TMail::Mail.new
      html_part.content_type = "text/html; charset=\"Shift_JIS\""
      html_part.transfer_encoding = "base64"
      html_part.content_disposition = nil
      html_body = @html_body.gsub(/<META[^>]*>/i, "<META http-equiv=\"Content-Type\" content=\"text/html; charset=Shift_JIS\">")
      html_part.body = [NKF.nkf("-s", html_body)].pack("m")

      rel_part = TMail::Mail.new
      rel_part.body = ""
      rel_part.content_type = "multipart/related"
      alt_part = TMail::Mail.new
      alt_part.body = ""
      alt_part.content_type = "multipart/alternative"

      alt_part.parts << text_part
      alt_part.parts << html_part

      rel_part.parts << alt_part
      @inl_parts.each { |pt| rel_part.parts << pt }

      mail.parts << rel_part
    else
      mail.parts << text_part
      @inl_parts.each { |pt| mail.parts << pt }
    end
    @att_parts.each { |pt| mail.parts << pt }

    mail
  end

  def to_au_format
    mail = TMail::Mail.new
    mail.body = ""
    mail.content_type = "multipart/mixed"

    text_part = TMail::Mail.new
    text_part.content_type = "text/plain; charset=\"iso-2022-jp\""
    text_part.transfer_encoding = "base64"
    text_part.content_disposition = nil
    text_part.body = [NKF.nkf("-j", @text_body)].pack("m")
    
    unless @html_body.empty? then
      html_part = TMail::Mail.new
      html_part.content_type = "text/html; charset=\"iso-2022-jp\""
      html_part.transfer_encoding = "base64"
      html_part.content_disposition = nil
      html_body = @html_body.gsub(/<META[^>]*>/i, "<META http-equiv=\"Content-Type\" content=\"text/html; charset=iso-2022-jp\">")
      html_part.body = [NKF.nkf("-j", html_body)].pack("m")

      alt_part = TMail::Mail.new
      alt_part.body = ""
      alt_part.content_type = "multipart/alternative"

      alt_part.parts << text_part
      alt_part.parts << html_part

      mail.parts << alt_part
    else
      mail.parts << text_part
    end

    @inl_parts.each { |pt| mail.parts << pt }
    @att_parts.each { |pt| mail.parts << pt }

    mail
  end

  def to_softbank_format
    mail = TMail::Mail.new
    mail.body = ""
    mail.content_type = "multipart/mixed"

    text_part = TMail::Mail.new
    text_part.content_type = "text/plain; charset=\"UTF-8\""
    text_part.transfer_encoding = "base64"
    text_part.content_disposition = nil
    text_part.body = [NKF.nkf("-w", @text_body)].pack("m")
    
    unless @html_body.empty? then
      html_part = TMail::Mail.new
      html_part.content_type = "text/html; charset=\"UTF-8\""
      html_part.transfer_encoding = "base64"
      html_part.content_disposition = nil
      html_body = @html_body.gsub(/<META[^>]*>/i, "<META http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">")
      html_part.body = [NKF.nkf("-w", html_body)].pack("m")

      rel_part = TMail::Mail.new
      rel_part.body = ""
      rel_part.content_type = "multipart/related"
      alt_part = TMail::Mail.new
      alt_part.body = ""
      alt_part.content_type = "multipart/alternative"

      alt_part.parts << text_part
      alt_part.parts << html_part

      rel_part.parts << alt_part
      @inl_parts.each { |pt| rel_part.parts << pt }

      mail.parts << rel_part
    else
      mail.parts << text_part
      @inl_parts.each { |pt| mail.parts << pt }
    end
    @att_parts.each { |pt| mail.parts << pt }

    mail
  end

  private

  def all_parts(mail)
    mail.parts.each do |part|
      all_parts(part, &Proc.new{ |i| yield(i) })
      yield(part)
    end
  end

  def generate_content_id
    t = Time.now.to_i
    "#{t}_#{rand(t)}@#{DOMAIN}"
  end
end
