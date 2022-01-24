from scripts.help import get_account, get_contract
from brownie import Swap, network, config, interface
from web3 import Web3
import time




def deploy_swap():
	account = get_account()
	swap = Swap.deploy(
		get_contract("weth_token").address,
		get_contract("price_feed_eth").address,
		get_contract("dao_token").address,
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
	amountOfDaoToApprove = Web3.toWei(100000000000000, "ether")
	amountOfWethToApprove = Web3.toWei(100000000000000, "ether")
	amountOfDao = Web3.toWei(100, "ether")
	amountOfWeth = Web3.toWei(0.01, "ether")
	approve_tx_weth = approve_erc20(amountOfWethToApprove, swap.address, get_contract("weth_token").address, account)
	approve_tx_dao = approve_erc20(amountOfDaoToApprove, swap.address, get_contract("dao_token").address, account)
	tx = swap.createPair(get_contract("dao_token").address, amountOfDao, amountOfWeth, {"from": account})
	tx.wait(1)
	print("Success")




def add_to_pair():
	account = get_account()
	swap = Swap[-1]
	amountOfDao = Web3.toWei(0.01, "ether")
	amountOfWeth = Web3.toWei(0.01, "ether")
	tx = swap.createPair(get_contract("dao_token").address, amountOfDao, amountOfWeth, {"from": account})
	tx.wait(1)



def check_price():
	account = get_account()
	swap = Swap[-1]
	tx_checkPrice = swap.checkPriceOfAPair(get_contract("dao_token").address, {"from": account})
	print(tx_checkPrice)



def check_balance():
	account = get_account()
	swap = Swap[-1]
	tx1, tx2, tx3, tx4 = swap.checkBalance({"from": account})
	print(tx1, tx2, tx3, tx4)



# First swap will be swapping dao for some eth.
# Second swap will be swapping eth for dao.



def swap_tokens_dao():
	account = get_account()
	swap = Swap[-1]
	tx = swap.swapTokens(
		get_contract("dao_token").address, 
		get_contract("weth_token").address, 
		Web3.toWei(100, "ether"), 
		{"from": account}
	)
	tx.wait(1)
	print("Swap successful!")

def swap_tokens_weth():
	account = get_account()
	swap = Swap[-1]
	tx = swap.swapTokens(
		get_contract("weth_token").address, 
		get_contract("dao_token").address, 
		Web3.toWei(0.01, "ether"), 
		{"from": account}
	)
	tx.wait(1)
	print("Second swap succesful")





def pay_out_providers():
	account = get_account()
	swap = Swap[-1]
	tx = swap.payOutToProviders(get_contract("dao_token").address, {"from": account})
	print(tx)






def main():
	deploy_swap()	
	create_pair()
	check_balance()	
	check_price()
	add_to_pair()
	check_price()
	check_balance()	
	swap_tokens_dao()
	check_balance()
	swap_tokens_weth()
	check_balance()
	pay_out_providers()
