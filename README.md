# Simple script for Hutton Truckers pinged systems
#### What does this do? ####
This script finds your current commander journal file. It then listens for the FSDJump event. when you jump to a new systerm that event it will download a list of systems that are over a month old from the Hutton Helper Background server and then work out your distance from them, it will then copy the nearest system name into your clipboard.

#### Why? ####
I was tired of looking at the website and manually copy and pasting the system names after every jump. So why not spend some time and save a few clicks? now all you have to do is jump into a system, set up you fuel scoop run (the game takes about 5-10 seconds to generate the FSDJump event) and as soon as its done that you can paste the next system name into the galaxy map and plot the next jump.
This Script saves you about 5 seconds on every jump. That soon adds up.

#### Whats needed? ####
1. You'll need ruby 3.1+ installed on your system as well as a handy gem called **file-tail**
2. You can find ruby by googling _**ruby installer windows**_
3. Then you can install the file-tail package called a 'gem' by running the following command in your command line : _**gem install file-tail**_
4. You can then run the ruby script by typing ruby pinged.rb in the command line in the directory that the file is located in.

#### Problems? ####
open an issue and let me know if your having problems and i'll do my best to sort them out. 
