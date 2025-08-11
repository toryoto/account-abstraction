import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { ethers } from 'hardhat'

const deploySimpleAccountFactory: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const provider = ethers.provider
  const from = await provider.getSigner().getAddress()
  const network = await provider.getNetwork()

  const isSepolia = network.chainId === 11155111

  if (!isSepolia) {
    console.log(`Skipping deployment on network with chainId: ${network.chainId}`)
    return
  }

  console.log(`Deploying SimpleAccountFactory on network: ${network.name} (chainId: ${network.chainId})`)

  const entrypointAddress = '0x4337084d9e255ff0702461cf8895ce9e3b5ff108'

  await hre.deployments.deploy(
    'SimpleAccountFactory', {
      from,
      args: [entrypointAddress],
      gasLimit: 6e6,
      log: true,
      deterministicDeployment: true
    })

  await hre.deployments.deploy('TestCounter', {
    from,
    deterministicDeployment: true,
    log: true
  })
}

deploySimpleAccountFactory.tags = ['simple-account-factory']

export default deploySimpleAccountFactory
