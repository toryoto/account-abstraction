import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { ethers } from 'hardhat'

const deployVerifyingPaymaster: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const provider = ethers.provider
  const from = await provider.getSigner().getAddress()
  const network = await provider.getNetwork()

  const isSepolia = network.chainId === 11155111

  if (!isSepolia) {
    console.log(`Skipping deployment on network with chainId: ${network.chainId}`)
    return
  }

  console.log(`Deploying VerifyingPaymaster on network: ${network.name} (chainId: ${network.chainId})`)

  const entrypointAddress = '0x4337084d9e255ff0702461cf8895ce9e3b5ff108'

  // 署名者のアドレス（環境変数から取得、またはデフォルト値を使用）
  const verifyingSigner = process.env.VERIFYING_SIGNER

  console.log(`EntryPoint address: ${entrypointAddress}`)
  console.log(`Verifying signer: ${verifyingSigner}`)

  const ret = await hre.deployments.deploy(
    'VerifyingPaymaster', {
      from,
      args: [entrypointAddress, verifyingSigner],
      gasLimit: 6e6,
      log: true,
      deterministicDeployment: true
    })

  console.log('==VerifyingPaymaster addr=', ret.address)
}

deployVerifyingPaymaster.tags = ['verifying-paymaster']

export default deployVerifyingPaymaster
