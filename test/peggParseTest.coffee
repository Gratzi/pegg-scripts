'use strict'
{expect, sinon, spy, stub, rewire, config} = require './TestHelper'
Promise = require 'bluebird'
PeggParse = require '../server/peggParse'
peggParseFixture = require './peggParseFixture'

describe 'PeggParse', ->
  beforeEach ->
    @pp = new PeggParse config.PARSE_APP_ID, config.PARSE_MASTER_KEY

  describe '#deleteCard', ->
    it 'deletes all the right things', ->
      # @pp.on 'message', (message) -> console.log message
      deleteStub = stub @pp._parse, 'deleteAsync', -> Promise.resolve()
      findStub = stub @pp._parse, 'findAsync'
      for own type, results of peggParseFixture.deleteCard.find
        findStub.withArgs(type).returns Promise.resolve results: results
      @pp.deleteCard 'MJ8vnhS9u5'
        .then =>
          expect(deleteStub).to.have.been.calledWith 'Card', 'MJ8vnhS9u5'
          expect(deleteStub).to.have.callCount 19
          for own type, results of peggParseFixture.deleteCard.find
            for res in results
              expect(deleteStub).to.have.been.calledWith type, res.objectId

  describe '#resetUser', ->
    it 'deletes all the right things', ->
      # @pp.on 'message', (message) -> console.log message
      deleteStub = stub @pp._parse, 'deleteAsync', -> Promise.resolve()
      updateStub = stub @pp._parse, 'updateAsync', -> Promise.resolve()
      findStub = stub @pp._parse, 'findAsync'
      findManyStub = stub @pp._parse, 'findManyAsync'
      for own type, results of peggParseFixture.resetUser.find
        findStub.withArgs(type).returns Promise.resolve results: results
      for own type, results of peggParseFixture.resetUser.findMany
        findManyStub.withArgs(type)
          .onFirstCall().returns Promise.resolve results: results
          .onSecondCall().returns Promise.resolve null
      @pp.resetUser 'UMKZeNXF3F'
        .then =>
          expect(deleteStub).to.have.callCount 4
          for own type, results of peggParseFixture.resetUser.find
            for res in results
              expect(deleteStub).to.have.been.calledWith type, res.objectId
          for card in peggParseFixture.resetUser.findMany.Card
              expect(updateStub).to.have.been.calledWith 'Card', card.objectId
              expect(card.hasPreffed).not.to.contain 'UMKZeNXF3F'
          for card in peggParseFixture.resetUser.findMany.Pref
              expect(updateStub).to.have.been.calledWith 'Pref', card.objectId
              expect(card.hasPegged).not.to.contain 'UMKZeNXF3F'


