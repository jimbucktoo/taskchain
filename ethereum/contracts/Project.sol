pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

contract ProjectFactory {
    address[] public deployedProjects;

    function createProject(string memory projectTitle, string memory projectDescription) public {
        address newProject = address(new Project(msg.sender, projectTitle, projectDescription));
        deployedProjects.push(newProject);
    }

    function getDeployedProjects() public view returns (address[] memory) {
        return deployedProjects;
    }

}

contract CollectionFactory {
    address[] public deployedCollections;

    function createCollection(address projectAddress, uint minimum, string memory collectionDescription) public {
        address newCollection = address(new Collection(msg.sender, projectAddress, miimum, collectionDescription));
        deployedCollections.push(newCollection);
    }

    function getDeployedCollections() public view returns (address[] memory) {
        return deployedCollections;
    }
}

contract Project {
    address[] public collections;
    address public projectManager;
    string public projectTitle;
    string public projectDescription;
    string[] public projectComments;

    modifier projectManagerRestricted() {
        require(msg.sender == projectManager);
        _;
    }

    constructor(address creator, string memory title, string memory description) public {
        projectManager = creator;
        projectTitle = title;
        projectDescription = description;
    }

    function createCollection(address collection) public projectManagerRestricted {
        collections.push(collection);
    }

    function getProjectCollections() public view returns (address[] memory){
        return collections;
    }
}

contract Collection {

    struct RequestInfo {
        uint dateCreated;
        uint dateAssigned;
        uint dateReviewed;
        uint dateCompleted;
    }

    struct Request {
        RequestInfo requestInfo;
        address reporter;
        string title;
        string description;
        uint value;
        string priority;
        string[] labels;
        uint dueDate;
        string link;
        string[] comments;
        address payable assignee;
        string status;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public collectionManager;
    address public project;
    uint public minimumContribution;
    string public collectionDescription;
    string[] public collectionComments;
    mapping(address => bool) public approvers;
    uint public approversCount;

    modifier collectionManagerRestricted() {
        require(msg.sender == collectionManager);
        _;
    }

    constructor(address creator, address projectAddress, uint minimum, string memory description) public {
        collectionManager = creator;
        project = projectAddress;
        minimumContribution = minimum;
        collectionDescription = description;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(address creator, string memory title, string memory description, uint value, string memory priority, string[] memory labels, uint dueDate, string memory link, string[] memory comments, address payable assignee, RequestInfo memory _newRequestInfo) public {

        RequestInfo memory newRequestInfo = RequestInfo({
            dateCreated: _newRequestInfo.dateCreated,
            dateAssigned: _newRequestInfo.dateAssigned,
            dateReviewed: _newRequestInfo.dateReviewed,
            dateCompleted: _newRequestInfo.dateCompleted
        });

        Request memory newRequest = Request({
            requestInfo: newRequestInfo,
            reporter: creator,
            title: title,
            description: description,
            value: value,
            priority: priority,
            labels: labels,
            link: link,
            dueDate: dueDate,
            comments: comments,
            assignee: assignee,
            status: "To Do",
            complete: false,
            approvalCount: 0
        });

        requests.push(newRequest);
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
        request.status = "approved";
    }

    function finalizeRequest(uint index) public collectionManagerRestricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);

        request.assignee.transfer(request.value);

        request.status = "completed";
        request.complete = true;
    }

    function getSummary() public view returns (
        uint, uint, uint, uint, address
    ) {
        return (
            minimumContribution,
            address(this).balance,
            requests.length,
            approversCount,
            collectionManager
        );
    }

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
}
