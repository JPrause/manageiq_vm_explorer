#
# Copyright 2007 ManageIQ, Inc.  All rights reserved.
#

require '../../../../build_tools/MiqCollectFiles'

cf = MiqCollectFiles.new(ARGV[0])
cf.verbose = true
cf.collect