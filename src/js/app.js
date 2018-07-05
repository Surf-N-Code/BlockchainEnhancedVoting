App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',

  init: function() {
    return App.initWeb3();
  },

  initWeb3: function() {
    if (typeof web3 !== 'undefined') {
      // If a web3 instance is already provided by Meta Mask.
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // Specify default instance if no web3 instance provided
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      web3 = new Web3(App.web3Provider);
    }
    return App.initContract();
  },

  castVote: function() {
      var candidateId = $('#candidatesSelect').val();
      var categoryId = $('.category').attr('categoryId');
      App.contracts.Election.deployed().then(function(instance) {
        return instance.addVoteForCandidateInCategory(categoryId, candidateId);
      }).then(function(result) {
        // Wait for votes to update
        $("#content").hide();
        $("#loader").show();
      }).catch(function(err) {
        console.error(err);
      });
  },
  toggleVotingResults: function() {
      App.contracts.Election.deployed().then(function(instance) {
          return instance.hasClosed();
      }).then(function(hasClosed) {
          console.log(hasClosed);
      });
  },

  listenForEvents: function() {
  App.contracts.Election.deployed().then(function(instance) {
    instance.votedEvent({}, {
      fromBlock: 0,
      toBlock: 'latest'
    }).watch(function(error, event) {
      console.log("event triggered", event)
      // Reload when a new vote is recorded
      App.render();
    });
  });
},

  initContract: function() {
    $.getJSON("Election.json", function(election) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.Election = TruffleContract(election);
      // Connect provider to interact with contract
      App.contracts.Election.setProvider(App.web3Provider);
      App.listenForEvents();
      App.render();
      return;
    });
  },

  render: function() {
    var electionInstance;
    var loader = $("#loader");
    var content = $("#content");
    var resultBlock = $('#resultsBlock');

    loader.show();
    content.hide();

    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);
      }
    });


    App.contracts.Election.deployed().then(function(instance) {

      let candidates;
      let candidateList;
      let candidatesCnt;
      let electionInstance = instance;

      return electionInstance.candidatesCount();
  }).then(function(candidatesCount) {

      candidatesCnt = candidatesCount;
      return electionInstance.hasClosed();
  }).then(function(hasClosed) {
      //@TODO change contract closing time and the !hasClosed here
        if(hasClosed) {
            console.log("Contract closed");
            resultBlock.show();
            getVotesForCandidatesInCategories(electionInstance, candidatesCnt, 0);
        } else {
            /**
             * Just to be safe, we will remove all result rows
             * if the contract is still active
             */
            console.log("Contract open");
            $("#voteResultsTable tr").remove();
            loader.hide();
            resultBlock.hide();
            content.show();
        }
        return electionInstance.voters(App.account);
    }).then(function(hasVoted) {
        console.log("has voted:" + hasVoted);
        // Do not allow a user to vote twice
        if(hasVoted) {
            console.log("user with accont "+ App.account +" already voted");
            $('form').hide();
            $('.alert-success').show().html("Thanks for your vote!");
        } else {
            var candidatesSelect = $('#candidatesSelect');
            candidatesSelect.empty
            numCandidates = returnCandidates();
            for (var i = 0; i < numCandidates.length; i++) {
                var id = numCandidates[i].id;
                var name = numCandidates[i].name;
                // Render candidate ballot option
                var candidateOption = "<option value='" + id + "' >" + name + "</ option>"
                candidatesSelect.append(candidateOption);
            }
        }
        $("#loader").hide();
        $("#content").show();
    }).catch(function(error) {
        console.warn(error);
    });
}

};
var resultsArray = new Array();
var categories = new Array();
categories.push("1. Overall Best Teacher");
categories.push("2. Best Altcoin Picks");
categories.push("3. Best Guard on Bitcoin Watch");
categories.push("4. Best ICO Contributions");
categories.push("5. Best FA Analysis");
categories.push("6. Best Shot Caller on Margin Plays");
categories.push("7. Best Contributions to Tools and Education");
categories.push("8. General Positive Influence on the Pound");

function getVotesForCandidatesInCategories(electionInstance, candidatesCnt, cat) {
    console.log("candidates count: "+candidatesCnt.toNumber());
    let candiateTemplate = new Array();
    for (var i = 1; i <= returnCandidates(); i++) {
        electionInstance.getCandidateResultsAndInfoFromCategory(cat,i).then(function(candidate) {
            var id = candidate[0];
            var name = candidate[1];
            var voteCount = candidate[2];
            if(voteCount > 0) {
            // Render results
                $('#cat'+cat+'Result').show();
                candiateTemplate += "<tr><th>" + id + "</th><td>" + name + "</td><td>" + voteCount + "</td></tr>";
                console.log("name: "+name);
                // App.renderResults(c,candidateTemplate)
                console.log("candidate template string: "+candiateTemplate);
            }
            if(id == 0 && cat < 8) {
                //i-1 should be last candidate with a vote now
                if(candiateTemplate.length > 0) {
                    resultsArray[cat] = candiateTemplate;
                    console.log("result array for cat: "+cat+" : "+resultsArray[cat]);
                    $('#candidatesResults'+cat).append(candiateTemplate);
                    $('#resTable').show();
                    cat++;
                    getVotesForCandidatesInCategories(electionInstance, candidatesCnt, cat);
                    addNewCategoryResultTable(cat);
                }
            }
        });
    }
}
function addNewCategoryResultTable(cat) {
    tblStr = `
            <div class="categoryResult" id="cat`+cat+`Result" style="display: none">
                <h3 class='text-center category' categoryId=`+cat+`>`+categories[cat]+`</h1>
                 <table class='table' id='resTable'>
                  <thead>
                    <tr>
                      <th scope='col'>#</th>
                      <th scope='col'>Name</th>
                      <th scope='col'>Votes</th>
                    </tr>
                  </thead>
                  <tbody id='candidatesResults`+cat+`'>
                  </tbody>
                </table>
            </div>`;
    $('#resultsBlock').append(tblStr);
}
//@TODO: parse Candidates from membership group and insert here
function returnCandidates() {
    var candidates = new Array();
    candidate1 =  {
        id: 1,
        name : "Dog 1"
    };
    candidate2 =  {
        id: 2,
        name : "Dog 2"
    };
    candidate3 =  {
        id: 3,
        name : "Dog 3"
    };
    candidates.push(candidate1);
    candidates.push(candidate2);
    candidates.push(candidate3);
    return candidates;
}
$(function() {
  $(window).load(function() {
    App.init();
  });
});
