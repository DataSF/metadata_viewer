require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra/base'
require 'rest-client'
require 'erb'
require 'json'
require 'prawn'
require "prawn/table"
require 'active_support/inflector'

class MetadataViewer < Sinatra::Base

  #for static files like css
  set :public_folder, File.dirname(__FILE__) + '/static'

  get '/' do
    'Hello World from MyApp in separate file!'
  end

  get '/metadata/:fbf' do
    fbf = params[:fbf]
    @dataset_info = getBaseMetaData(fbf)
    @asset_info = getDatasetInfo(fbf)
    @dataset_info = @dataset_info.merge(@asset_info[0])
    cols_mapper = {}
    for k,v in @dataset_info
      cols_mapper[k] = k.titleize
    end
    @dataset_info = keyMapper(@dataset_info,cols_mapper)
    erb :metadata
  end


  get '/metadatapdf/:fbf' do
    fbf = params[:fbf]
    content_type 'application/pdf'
    @dataset_info = getBaseMetaData(fbf)
    @asset_info = getDatasetInfo(fbf)
    @dataset_info = @dataset_info.merge(@asset_info[0])
    cols_mapper = {}
    for k,v in @dataset_info
      cols_mapper[k] = k.titleize
    end
    dataset_info = keyMapper(@dataset_info,cols_mapper)
    pdf = Prawn::Document.new
    meta_info = []
    for k,v in dataset_info
      if k != 'Fields'
        item = [  "• <b>" + k +"</b>" + ": " + v.to_s ]
        meta_info.push(item)
      end
    end
    pdf.text dataset_info['Dataset Name'], :align=> :center, :size => 18
    pdf.move_down 20
    field_data = [['<b>Field Name </b>', '<b>Field Type</b>', '<b>Field Definition</b>']]
    dataset_info['Fields'].each do |field|
      field_piece = [ field['field_name'], field['field_type'], field['field_definition']]
      field_data.push(field_piece)
    end
    #field_data = [[Prawn::Table::Cell::Text.new( pdf, [0,0, 0], :content => "<b>1. Row example text</b> \n\nExample Text Not Bolded", :inline_format => true), "433", ],
    #
    pdf.table( meta_info, :cell_style => {:size => 10, :inline_format => true, :border_width => 0, :padding => 1 },  :width => 500)
    pdf.move_down 20
    pdf.table( field_data,:cell_style => {:size => 11, :inline_format => true, :padding => 1 , :border_width => 0.5},  :width => 500)
    pdf.render
  end
  helpers do
    def keyMapper(myhash, keyMapping)
      return myhash.map {|k, v| [keyMapping[k], v] }.to_h
    end

    def getBaseMetaData(fbf)
      metadataset_url = "https://data.sfgov.org/resource/wn8x-uk7i.json"
      cols_to_select = "columnid,dataset_name,field_name,api_key,inventoryid,datasetid,field_type,data_dictionary_attached, department,field_alias,field_definition,field_type_flag,field_documented,attachment_url"
      select_qry = "?$select=" + cols_to_select
      where_qry = "&datasetid=" + fbf
      qry = metadataset_url+select_qry+where_qry
      fields = issue_qry(qry)
      dataset_info = {}
      keys_to_keep = ['field_name', 'field_type', 'field_alias', 'field_definition', 'field_type_flag']
      if fields.respond_to?('each') and fields.count > 1
        dataset_info['dataset_name'] = fields[0]['dataset_name']
        dataset_info['inventory_id'] = fields[0]['inventoryid']
        dataset_info['department'] = fields[0]['department']
        dataset_info['dataset_url'] = "https://data.sfgov.org/resource/"+ fields[0]['datasetid']
        #@dd_attached = fields[0]['data_dictionary_attached'
        fields = fields.map do |hash|
          hash.select do |key, value|
            keys_to_keep.include? key
          end
        end
      end
      dataset_info['fields'] =  fields
      return dataset_info
    end

    def getDatasetInfo(fbf)
      asset_info_url =  "https://data.sfgov.org/resource/g9d8-sczp.json"
      cols_to_select = "description,visits,creation_date,downloads,category,keywords,license,geographic_unit,publishing_frequency,data_change_frequency"
      select_qry = "?$select=" + cols_to_select
      where_qry = "&u_id=" + fbf
      qry = asset_info_url+select_qry+where_qry
      asset_info = issue_qry(qry)
      return asset_info
    end

    def issue_qry(qry)
      result = ""
      result = RestClient.get(qry)
      resp_code =  result.code
      response = ""
      if resp_code == 200
        response = JSON.parse(result)
        if response.count < 1
          response = "Error 404: Dataset Not Found"
        end
      elsif resp_code == 400
        response = "Error 400: Bad request!"
      else
        response = "Server ERROR!"
      end
      return response
    end
  end




#end of server
end
