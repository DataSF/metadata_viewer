require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra/base'
require 'rest-client'
require 'erb'
require 'json'


class MetadataViewer < Sinatra::Base

  #for static files like css
  set :public_folder, File.dirname(__FILE__) + '/static'

  get '/' do
    'Hello World from MyApp in separate file!'
  end

  get '/metadata/:fbf' do
    fbf = params[:fbf]
    keys_to_keep = ['field_name', 'field_type', 'field_alias', 'field_definition', 'field_type_flag']
    metadataset_url = "https://data.sfgov.org/resource/wn8x-uk7i.json"
    cols_to_select = "columnid,dataset_name,field_name,api_key,inventoryid,datasetid,field_type,data_dictionary_attached, department,field_alias,field_definition,field_type_flag,field_documented,attachment_url"
    select_qry = "?$select=" + cols_to_select
    where_qry = "&datasetid=" + fbf
    qry = metadataset_url+select_qry+where_qry
    result = ""
      result = RestClient.get(qry)
    resp_code =  result.code
    fields = ""
    error = ""
    if resp_code == 200
      fields = JSON.parse(result)
      if fields.count < 1
        error = "Dataset Not Found"
      end
    else
      error = "Server ERROR!"
    end
    if fields != ""
      @dataset_name = fields[0]['dataset_name']
      @inventoryid = fields[0]['inventoryid']
      @department = fields[0]['department']
      @dataset_url = "https://datasf.org/resource/"+ fields[0]['datasetid']
      #@dd_attached = fields[0]['data_dictionary_attached'
      fields = fields.map do |hash|
        hash.select do |key, value|
        keys_to_keep.include? key
        #need to add back in the missing keys
        end
      end
      @dataset_info = fields
    else
      @dataset_info = error
    end
    erb :metadata

  end

end
