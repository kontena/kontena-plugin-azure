
module Kontena::Plugin::Azure::Common
  LOCATIONS = [
    'East US',
    'East US 2',
    'Central US',
    'North Central US',
    'South Central US',
    'West Central US',
    'West US',
    'West US 2',
    'US Gov Virginia',
    'US Gov Iowa',
    'Canada East',
    'Canada Central',
    'Brazil South',

    'North Europe',
    'West Europe',
    'Germany Central',
    'Germany Northeast',
    'UK West',
    'UK South',

    'Southeast Asia',
    'East Asia',
    'Australia East',
    'Australia Southeast',
    'Central India',
    'West India',
    'South India',
    'Japan East',
    'Japan West',
    'China East',
    'China North'
  ].freeze

  def locations
    LOCATIONS
  end
end
