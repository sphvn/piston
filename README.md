# README #

### What is? ###

* Piston
* 0.0.0.0

### How do I get set up? ###

* Clone the repository to local machine
* Install NodeJS `http://nodejs.org/`
* Run `npm install LiveScript -g`
* Install Python >= v2.5.0 & < 3.0.0 `https://www.python.org/downloads/` and add to `PATH` this is required for `npm install serialport`
* Run `npm install` to install required npm dependencies, see `package.json` for details
* Run `livescript -wc .` in the directory to watch / compile
* Run `npm test` to run unit tests in the /tests directory
* Run `node main {port} {decoder} {udp|com} {udp-port}` to run the application
