## statlink-keen

Sends heatpump stats from [Husdata](http://husdata.se/) Statlink Raspberry box to Keen.IO

### Install

Install node:

    wget http://node-arm.herokuapp.com/node_latest_armhf.deb
    sudo dpkg -i node_latest_armhf.deb

Clone this repo on your pi and install the software:

    git clone https://github.com/raimohanska/statlink-keen.git
    cd statlink-keen
    npm install

Create the file `keep-config.coffee` in the `statlink-keen` directory and add your Keen.IO configuration there. Like this:

```coffeescript
module.exports = {
  projectId: "YOURPROJECTIT"
  writeKey: "YOURWRITEKEY"
}
```

Schedule the `statlink-keen` script to be run hourly in your `etc/crontab` file:

    0  *    * * *   root    python /home/pi/statlink-keen/statlink-keen
