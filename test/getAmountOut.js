// const k = 10 ** 18
// const reserveInput = Math.sqrt(k)
// const reserveOutput = Math.sqrt(k)
// const sum = 1000000000
// const amount = [1]
// while (amount.length < sum) {
//     amount.push(amount.length + 1)
// }

// amount.forEach(a => {
//     // const b = _getAmountOut1(a, reserveInput, reserveOutput)
//     // const c = _getAmountOut2(a, reserveInput, reserveOutput)
//     // const d = _getAmountOut3(a, reserveInput, reserveOutput)

//     const diffK = reserveOutput * (reserveInput + a) - k
//     const amountOut = diffK / (reserveInput + a)
//     const newK = (reserveOutput - amountOut) * (reserveInput + a)

//     console.log("diffK-->", diffK)
//     console.log("amountOut-->", amountOut)
//     console.log("newK-->", newK)
//     console.log("a-->", a)
//     console.log("newK > old K -->", newK > k)

//     // if (b != d) {
//     //     console.group(`When original k = ${k}, amount= ${a}:`)
//     //     console.log(
//     //         "1️⃣ AmoutOut:",
//     //         b,
//     //         ", Is new k >= old k ?",
//     //         (Math.sqrt(k) + a) * (Math.sqrt(k) - b) >= k ? "✅" : "❌",
//     //     )
//     //     console.log(
//     //         "2️⃣ AmoutOut:",
//     //         c,
//     //         ", Is new k >= old k ?",
//     //         (Math.sqrt(k) + a) * (Math.sqrt(k) - c) >= k ? "✅" : "❌",
//     //     )
//     //     console.log("❌ 1️⃣ != 3️⃣")
//     //     console.log(
//     //         "3️⃣ AmoutOut:",
//     //         d,
//     //         ", Is new k >= old k ?",
//     //         (Math.sqrt(k) + a) * (Math.sqrt(k) - d) >= k ? "✅" : "❌",
//     //     )
//     //     console.groupEnd(`When original k = ${k}, amount= ${a}:`)
//     // }
// })

// function _getAmountOut1(amountIn, reserveInput, reserveOutput) {
//     return Math.floor((amountIn * reserveOutput) / (reserveInput + amountIn))
// }

// function _getAmountOut2(amountIn, reserveInput, reserveOutput) {
//     const oldK = reserveInput * reserveOutput
//     const newReserveInput = reserveInput + amountIn
//     const newReserveOutput = Math.floor(oldK / newReserveInput)
//     return reserveOutput - newReserveOutput
// }

// function _getAmountOut3(amountIn, reserveInput, reserveOutput) {
//     const oldK = reserveInput * reserveOutput
//     const newReserveInput = reserveInput + amountIn
//     // @dev (newReserveInput - 1) if for round to 1
//     const newReserveOutput = Math.floor((oldK + (newReserveInput - 1)) / newReserveInput)
//     return reserveOutput - newReserveOutput
// }
