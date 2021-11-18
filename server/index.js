//import * as express from 'express'
//import * as shelljs from 'shelljs'
//import * as pg from 'pg'
//import logger from './logger' 
//import * as database from './db'
const express = require('express')
const shelljs = require('shelljs')
const pg = require('pg')
const logger = require('./logger').logger
const db = require('./db')


const HTTP_PORT = 8080

const logErrors = (err, next) => {
  logger.error(err.stack);
  next(err);
}

const signupRouter = express.Router()
signupRouter.get('/echo', function(req, res){
  logger.info('-----req.query:-----')
  logger.info(req.query)
  db.ping()
  res.send({
    hello: 'world'
  })
})

function initApp() {
  let app = express()

  app.use(express.urlencoded({extended: true}))
  app.use(express.json())
  app.use('/signup/', signupRouter)

  app.use(function (err, req, res, next) {
    logErrors(err, next)
    res.status(err.status || 500).send(err.message)
  });

  app.use(function(req, res, next) {
    res.status(404).send('Invalid request...');
  });

  return app;
}

function startServer() {
  let app = initApp()
  app.listen(HTTP_PORT, function () {
    logger.info('server is listening on port ' + HTTP_PORT);
  });
}

async function main() {
   startServer()
}

main()