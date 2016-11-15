A Ruby library to interface with the fine thermostats from [Sinope Technologies](http://www.sinopetech.com/en/) and their web backend [Neviweb](https://neviweb.com/).

Inspired heavily by the official [SmartThings driver](https://github.com/sinopetechnologies/smartThings).

#### Example usage
 
```
require './sinope'
require 'pp'

my_house = Sinope.new('email', 'password')
# toggle home/away status
status = home_away_status()
if status == Sinope::HOME
    puts "Current home/away status: HOME"
    my_house.away()
elsif status == Sinope::AWAY
    puts "Current home/away status: AWAY"
    my_house.home()
end
pp my_house.status()
```


##### TODO
- Implement setpoint()
- Make this a Gem

