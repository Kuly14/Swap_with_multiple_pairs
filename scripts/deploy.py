from brownie import Swap, config, network, interface
from scripts.help import get_account
from web3 import Web3




dao_address = config["networks"][network.show_active()]["dao_token"]
weth_address = config["networks"][network.show_active()]["weth_token"]


def start_swap():
	account = get_account()
	swap = Swap.deploy(config["networks"][network.show_active()]["weth_token"], 
		config["networks"][network.show_active()]["price_feed_eth"], 
		dao_address,
		{"from": account} 
	)


def approve_erc20(amount, spender, erc20_address, account):
    print("Approving ERC20 token...")
    erc20 = interface.IERC20(erc20_address)
    tx = erc20.approve(spender, amount, {"from": account})
    tx.wait(1)
    print("Approved!")
    return tx



def create_pair():
	account = get_account()
	swap = Swap[-1]
	amountOfDaoToApprove = Web3.toWei(10000, "ether")
	amountOfWethToApprove = Web3.toWei(1000, "ether")
	amountOfDao = Web3.toWei(100, "ether")
	amountOfWeth = Web3.toWei(0.01, "ether")
	approve_tx_weth = approve_erc20(amountOfWethToApprove, swap.address, weth_address, account)
	approve_tx_dao = approve_erc20(amountOfDaoToApprove, swap.address, dao_address, account)
	tx = swap.createPair(dao_address, amountOfDao, amountOfWeth, {"from": account})
	boolena = swap.funcWasTrue()
	print(boolena)
	print("Pair created")
	print(tx)


def add_to_pair():
	account = get_account()
	swap = Swap[-1]
	amountOfDao = Web3.toWei(100, "ether")
	amountOfWeth = Web3.toWei(0.01, "ether")
	tx = swap.createPair(dao_address, amountOfDao, amountOfWeth, {"from": account})
	tx.wait(1)
	wethISpent = swap.wethIreceived()
	boolena = swap.funcWasTrue()
	ratio = swap.ratioToReceive()
	print(wethISpent)
	print(boolena)
	print(ratio)
	print("Success")

def latest_price():
	account = get_account()
	swap = Swap[-1]
	tx = swap.getLatestPrice({"from": account})
	print(tx)


def checkPriceOfAPairScript():
	account = get_account()
	swap = Swap[-1]
	tx = swap.checkPriceOfAPair(dao_address, {"from": account})
	nums = swap.num();
	print(nums)


def checkIfPairExistsInTHecontract():
	account = get_account()
	swap = Swap[-1]
	tx = swap.checkIfPairExists(dao_address, {"from": account})
	tx.wait(1)
	pariexists = swap.pairExists();
	print(pariexists)



def withdraw():
	account = get_account()
	swap = Swap[-1]
	tx = swap.withdraw({"from": account})
	tx.wait(1)
	print("All tokens withdrawn")



def main():
	start_swap()
	create_pair()
	latest_price()
	add_to_pair()
	add_to_pair()
	checkPriceOfAPairScript()
	checkIfPairExistsInTHecontract()
	withdraw()


	# THe problem is in check if pair exists function.