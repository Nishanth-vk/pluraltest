var express = require('express');

var app = express()

app.get('/', function(req, res){
  res.send('Hello World after updating changes');
});

  app.listen(3000);
  console.log('Express started on port 3000');
