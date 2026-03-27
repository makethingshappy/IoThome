# If you wish to test and run both drivers on startup you can simply run 
# an "autoexec.be" which basically runs both drivers even if you turn your
# ESP device on/off or restart

# To run this file you can either do br load("autoexec_demo.be")
# or rename the file from "autoexec_demo.be" to "autoexec.be"

# It's recommended that you write your own berry application code in "autoexec.be"

# We load both drivers, so that they run in the background / startup
load("ADS1115Data.be")
#load("ADS7828.be") # uncommment and comment ADS1115 if using IoTextra Analog 3 which uses ADS7828
load("TCA9534.be")
