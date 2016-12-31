

#prawn library seems pretty stable to do this.
#xample controller to generate/download pdfs
require "prawn"
class ClientsController < ApplicationController

  def download_pdf
    client = Client.find(params[:id])
    send_data generate_pdf(client),
              filename: "#{client.name}.pdf",
              type: "application/pdf"
  end

  private

  def generate_pdf(client)
    Prawn::Document.new do
      text client.name, align: :center
      text "Address: #{client.address}"
      text "Email: #{client.email}"
    end.render
  end

#http://stackoverflow.com/questions/13164063/file-download-link-in-rails
