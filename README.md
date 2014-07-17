# README #

### What is? ###

* Piston
* 0.0.0.0

### How do I get set up? ###

* Clone the repository to local machine
* Install NodeJS `http://nodejs.org/`
* Run `npm install LiveScript -g`
* Install Python and ensure it is available in the `PATH` this is required for the `npm install serialport`
* Run `npm install` to install required npm dependencies, see `package.json` for details
* Run `livescript -wc .` in the directory to watch / compile
* Run `npm test` to run unit tests in the /tests directory
* Run `node main.js` to run the application

### Running NodeJS behind the Fugro proxy... ###

* Set the `HTTP_PROXY` & `HTTPS PROXY` in environment variables or profile `http://username:password@172.23.0.70:80`
* Set the npm http proxy `npm config set proxy http://username:password@172.23.0.70:80`
* Set the npm https proxy `npm config set https-proxy http://username:password@172.23.0.70:80`
* Set the registry to use the http instead of https `npm config set registry http://registry.npmjs.org/`


### Who do I talk to? ###

* Stephen "The Magician" Underwood
* David "The Guru" Coombes