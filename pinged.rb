require 'file-tail'
require 'json'
require 'net/http'
require 'time'
require 'win32ole'

# find the user folder name
# found from here https://stackoverflow.com/questions/6777453/how-can-i-get-the-username-of-the-person-who-initialised-the-file-in-ruby
network=WIN32OLE.new("Wscript.Network")
user = network.username

# Specify the path to the journal file
path_to_journal = "C:\\Users\\#{user}\\Saved Games\\Frontier Developments\\Elite Dangerous"

# This grabs  and parses the complete list of old systems ready for processing when the journal generates a FSDJump event
@uri = URI('http://hot.forthemug.com:4567/pinged.json')
@old_systems = {}

# Set the jump counter after every 30 jumps the pinged list is redownloaded ()
@jump_counter = 0


# add systems that have been used to this so that when we re-download the old_systems data
# in the event that the list hasnt refreshed our jump we can eliminate it and prevent
# a double back
@used_systems = []


def process_fsd_jump(data)
  #remove the system from the @old_system list to prevent loop backs
  @old_systems = @old_systems.except(data['StarSystem'])
  @distances = {}
  @jump_counter += 1
  # use the FSDJump data to get the starpos x,y and z

  current_x = data['StarPos'][0]
  current_y = data['StarPos'][1]
  current_z = data['StarPos'][2]
  # iterate through the old systems data we got from the HH server and work out our distance to all of the others
  # and store that data in @distances
  @old_systems.each do |name, pos|
    dest_x = pos[0]
    dest_y = pos[1]
    dest_z = pos[2]
    distance = Math.sqrt(((dest_x - current_x) ** 2) + ((dest_y - current_y) ** 2) + ((dest_z - current_z) ** 2))
    distance = distance.round(2)
    if distance == 0.0
      next
    end
    @distances[name] = distance
  end
  # sort @distances by ... err... distance
  @distances = @distances.sort_by{|k,v| v}
  # select first system in the sorted list
  selected_system = @distances.first
  # get the name of the system, the distance part is unimportant
  selected_system_name = selected_system[0]
  puts "[#{@jump_counter}][#{Time.now.utc.iso8601}] Your next system is #{selected_system_name}"

  # push the name into the clipboard
  IO.popen('clip', 'w') { |pipe| pipe.puts selected_system_name }
 
  @used_systems << selected_system_name
  # when the counter reaches 30 reprocess the old_systems list from the HH server
  if @jump_counter > 29
    puts "[#{@jump_counter}][#{Time.now.utc.iso8601}] Resetting the counter and updating the list"
    reprocess_old_systems_list(@used_systems)
    @jump_counter = 1
  end
end

def reprocess_old_systems_list(used_systems)
  # get the new list of systems and then remove the systems from used_systems
  get_systems()
  used_systems.each do |name|
    @old_systems = @old_systems.except(name)
  end
  # reset the used systems, any systems should have been cleared from the list by the next reload
  @used_systems = []
end

def get_systems()
  @old_systems = JSON.parse(Net::HTTP.get(@uri))
end

# Get the systems from the server
get_systems()

# get the list of files in that directory
files_sorted_by_time = Dir.children(path_to_journal)

# declare the array that stores the list
log_files = []

files_sorted_by_time.each do |name|
  # only include the .log files
  if name.include?(".log")
    log_files << name
  end
end

# sort and reverse the log files so the newest file is first
log_files = log_files.sort.reverse

# setting this up so we can set this to false to end the program if the Shutdown event is caught in the log file
should_run = true

# opens the path and the newest file and tails the log
# this program should be run after the game has started so that the correct file is selected
# elite dangerous only generates a journal file once the game is loaded and past the splash screen
while should_run do
  File::Tail::Logfile.tail("#{path_to_journal}\\#{log_files.first}", :backward => 30) do |line|
    data = JSON.parse(line)
    # puts data
    if data['event'] == "Shutdown"
      puts "Shutting down program in 5 seconds"
      sleep(5)
      should_run = false
      break
    end
    if data['event'] == "FSDJump"
      puts "[#{@jump_counter}][#{Time.now.utc.iso8601}] FSDJUMP into #{data['StarSystem']}. Finding your next system..."
      process_fsd_jump(data)
    end
  end
end
