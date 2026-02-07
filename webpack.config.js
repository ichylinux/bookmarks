const path = require('path')
const { VueLoaderPlugin } = require('vue-loader')

module.exports = {
  entry: {
    head_box: path.resolve(__dirname, 'app/javascript/packs/head_box.js')
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, 'public/packs'),
    publicPath: '/packs/'
  },
  resolve: {
    extensions: ['.js', '.vue', '.erb']
  },
  module: {
    rules: [
      {
        test: /\.vue(\.erb)?$/,
        use: [{ loader: 'vue-loader' }]
      },
      {
        test: /\.erb$/,
        enforce: 'pre',
        exclude: /node_modules/,
        use: [
          {
            loader: 'rails-erb-loader',
            options: {
              runner: (/^win/.test(process.platform) ? 'ruby ' : '') + 'bin/rails runner'
            }
          }
        ]
      },
      {
        test: /\.css$/,
        use: ['vue-style-loader', 'css-loader']
      }
    ]
  },
  plugins: [new VueLoaderPlugin()],
  devServer: {
    host: 'localhost',
    port: 3035,
    headers: {
      'Access-Control-Allow-Origin': '*'
    },
    devMiddleware: {
      publicPath: '/packs/'
    },
    static: {
      directory: path.resolve(__dirname, 'public')
    }
  }
}
