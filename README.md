# README

Ruby version: 2.3.7<br />
Rails version: 5.2.2

Steps to run this app locally:
```
$ bundle install --path .bundle     # Install dependencies
$ rake db:setup                     # Setup database
$ rails s                           # Start server
```

After server is started, the API can be called using the path `localhost:3000/api`.

The unit tests can be found in `GeekInsider-TAP.postman_collection.json` under the root folder.
