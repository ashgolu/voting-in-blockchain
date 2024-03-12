// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
contract election{
    address votingAdmin;
    bool votingStarted;
    uint totalVote;
    uint endVote;
    string status;
    uint totalVoter;
    string  winner;
    uint highestVote;
    enum vStatus{notStarted,ongoing,ended}
    vStatus choice;

// contructor call to initialize global variable
constructor() {
    votingAdmin=msg.sender;
    votingStarted=false;
    totalVote=0;
    status="Not Started";
    endVote=0;
    totalVoter=0;
    highestVote=0;
    choice=vStatus.notStarted;
}

// candidate stucture
    struct candidates{
        address candidateAddress;
        string name;
        string proposal;
        bool register;
        uint votes;
    }

// voter structure
    struct voters{
        address voterAddress;
        bool register;
        bool voted;
        bool isDelegateVote;
        uint transferedVote;
        uint id;
        string name;
    }

    mapping (address=>candidates) public CandidateList;
    candidates[] private  displayCandidates;

    mapping (address=>voters) public VoterList;
    voters[] private  displayVoter;

// function to register candidate
    function registerCandidate(string memory _name, string memory _proposal,address _candidateAddress)  public{
        require(votingStarted==false);
        require(votingAdmin==msg.sender,"only admin can register candidate");
        require(CandidateList[_candidateAddress].register!=true,"candidate already exist");
        require(_candidateAddress!=votingAdmin,"admin can't be registered as candidate");
        candidates memory Candidate = candidates({
            candidateAddress:_candidateAddress,
            name:_name,
            proposal:_proposal,
            register:true,
            votes:0
        });
        CandidateList[_candidateAddress]=Candidate;
        displayCandidates.push(Candidate);
    }

// function to display candidates
function allCandidates()view public returns (candidates[]memory){
    return displayCandidates;
}

// function to register voter
    function registerVoter( address _voterAddress,string memory name)   public {
        require(votingStarted==false);
        require(votingAdmin==msg.sender,"only admin can register voter");
        require(_voterAddress!=votingAdmin,"admin cannot register for vote");
        require(VoterList[_voterAddress].register==false,"voter already registered");
        voters memory voter=voters({
            register:true,
            voted:false,
            isDelegateVote:false,
            voterAddress:_voterAddress,
            transferedVote:0,
            id:displayVoter.length,
            name:name
        } );
        VoterList[_voterAddress]=voter;
        displayVoter.push(voter);
    }

// function to display voters
    function allVoters() view public returns(voters[] memory){
        return  displayVoter;
    }

// function to start the voting
function startVoting()public {
    require(votingAdmin==msg.sender&&endVote==0&&votingStarted==false);
    votingStarted=true;
    choice=vStatus.ongoing;
    status="On Going";
}

// function to end the voting
function endVoting()public{
    require(votingAdmin==msg.sender&&votingStarted==true&&endVote==0);
    endVote=1;
    choice=vStatus.ended;
    status="Voting Ended";
}

// function to show the status of election
function votingStatus()view public returns (string memory){
    return status;
}

// function to cast vote
function CastVote(uint _id,address _candidateAddress)  public{
 require(checkVoter(msg.sender)==true,"voter does not exist");
 require(VoterList[msg.sender].voted==false||VoterList[msg.sender].transferedVote!=0,"already voted");
 require(votingStarted==true,"voting not started");
 uint VId= VoterList[msg.sender].id;
 CandidateList[_candidateAddress].votes++;
 displayCandidates[_id]= CandidateList[_candidateAddress];
 totalVoter++;
 if(highestVote<displayCandidates[_id].votes){
    highestVote=displayCandidates[_id].votes;
    winner=displayCandidates[_id].name;
 }
 if(VoterList[msg.sender].transferedVote!=0){
    VoterList[msg.sender].transferedVote--;
    displayVoter[VId].transferedVote--;
 }
 else{
     VoterList[msg.sender].voted=true;
     displayVoter[VId].voted=true;
 }
}

// function to check voter is registered or not
function checkVoter(address _msgSender) view  private returns(bool){
    bool Exist=false;
    for (uint i=0; i<displayVoter.length; i++) 
    {
        if(displayVoter[i].voterAddress==_msgSender){
           Exist=true;
           break ;
        }
        else{
            Exist=false;
        }
    }
    return Exist;
}

// function to display the winner
function winnerDeclare( ) view  public returns(string memory) {
   require(votingAdmin==msg.sender,"only admin can declare winner");
   require(choice==vStatus.ended,"WINNER WILL ONLY BE DECLARED ONCE THE ELCTION ENDS");
   return winner;
}
// function to delegate vote
function delegateVote( address _delegate)   public  {
    uint _senderID=VoterList[msg.sender].id;
    uint _receiverID=VoterList[_delegate].id;
    require(choice==vStatus.ongoing,"voting must be ongoing to delegate vote");
    require(displayVoter[_senderID].voterAddress==msg.sender);
    require(VoterList[msg.sender].voted==false||VoterList[msg.sender].transferedVote!=0,"only those can delegate vote who have not voted yet");
    require(votingAdmin!=msg.sender,"admin cannot delegate vote");
    require(msg.sender!=_delegate,"Cannot delegate vote to self");
    require(CandidateList[msg.sender].register!=true&&CandidateList[_delegate].register!=true,"Candidate cannot accept and transfer votes");
     VoterList[_delegate].transferedVote++;
    if (VoterList[msg.sender].transferedVote==0){
        VoterList[msg.sender].voted=true;
        VoterList[msg.sender].isDelegateVote=true;
        displayVoter[_senderID].voted=true;
        displayVoter[_senderID].isDelegateVote=true;
        displayVoter[_receiverID].transferedVote++;
    }
    else{
        VoterList[msg.sender].transferedVote--;
        displayVoter[_senderID].transferedVote--;
        displayVoter[_receiverID].transferedVote++;
        displayVoter[_senderID].isDelegateVote=true;
    }
}
}