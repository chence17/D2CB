/*
 * @Author: your name
 * @Date: 2021-11-26 21:37:38
 * @LastEditTime: 2021-11-27 09:14:33
 * @LastEditors: Please set LastEditors
 * @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 * @FilePath: /example/truffle-config.js
 */
module.exports = {
  networks: {
   development: {
     host: "127.0.0.1",
     port: 7545,
     network_id: "*"
   },
   test: {
     host: "127.0.0.1",
     port: 7545,
     network_id: "*"
   }
  },
  compilers: {
    solc: {
      version: "/usr/lib/node_modules/solc"
    }
  }
};
