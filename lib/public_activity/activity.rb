require 'active_record'
require 'ostruct'
require 'erb'

module PublicActivity
  # The ActiveRecord model containing 
  # details about recorded activity.
  class ErbBinding < OpenStruct
    def get_binding
      return binding()
    end
  end

  class Activity < ActiveRecord::Base
    # Define polymorphic association to the parent
    belongs_to :trackable, :polymorphic => true
    # Define ownership to a resource responsible for this activity
    belongs_to :owner, :polymorphic => true
    # Serialize parameters Hash
    serialize :parameters, Hash
    
    class_attribute :template

    attr_accessible :key, :owner, :parameters
    # Virtual attribute returning text description of the activity
    # using basic ERB templating
    #
    # == Example:
    #
    # Let's say you want to show article's title inside Activity message.
    #
    #   #config/pba.yml
    # activity:
    #   article:
    #     create: "New <%= trackable.name %> article has been created"
    #     update: 'Someone modified the article'
    #     destroy: 'Someone deleted the article!'
    #
    # And in controller:
    #
    #   def create
    #     @article = Article.new
    #     @article.title = "Rails 3.0.5 released!"
    #     @article.activity_params = {:title => @article.title}
    #     @article.save
    #   end
    #
    # Now when you list articles, you should see:
    #   @article.activities.last.text #=> "Someone has created an article 'Rails 3.0.5 released!'"
    def text(params = {})
      begin
        erb_template = resolveTemplate(key)
        if !erb_template.nil? 
          parameters.merge! params
          vars = ErbBinding.new(parameters)
          renderer = ERB.new(erb_template)
          vars_binding = vars.send(:get_binding)
          renderer.result(vars_binding)
        else
          "Template not defined"
        end
      rescue
        "Template not defined"
      end
    end
    
    private
    def resolveTemplate(key)
       res = nil
       if !self.template.nil?
         key.split(".").each do |k|
           if res.nil?
             res = self.template[k]
           else
             res = res[k]
           end
         end
        end
       res
    end
  end  
end
