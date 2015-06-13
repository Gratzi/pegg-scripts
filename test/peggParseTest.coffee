'use strict'
{expect, sinon, spy, stub, rewire, config} = require './TestHelper'
Promise = require 'bluebird'
PeggParse = require '../server/peggParse'
parseFixture = require './parseFixture'

describe 'PeggParse', ->
  beforeEach ->
    @pp = new PeggParse config.PARSE_APP_ID, config.PARSE_MASTER_KEY

  describe '#deleteCard', ->
    it 'deletes all the right things', ->
      deleteStub = stub @pp._parse, 'deleteAsync', -> Promise.resolve()
      findStub = stub @pp._parse, 'findAsync'
      for own type, results of parseFixture.deleteCard
        findStub.withArgs(type).returns Promise.resolve results: results
      @pp.deleteCard 'MJ8vnhS9u5'
        .then =>
          expect(deleteStub).to.have.been.calledWith 'Card', 'MJ8vnhS9u5'
          for own type, results of parseFixture.deleteCard
            for res in results
              expect(deleteStub).to.have.been.calledWith(type, res.objectId)


