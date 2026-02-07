require 'daddy/itamae'

include_recipe '../cookbooks/base.rb'

package 'graphviz' do
  user 'root'
end

include_recipe '../cookbooks/gem.rb'
