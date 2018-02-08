import * as basegl from 'basegl'

import {ExpressionNode}  from 'view/ExpressionNode'
import {NodeEditor}      from 'view/NodeEditor'
import {subscribeEvents} from 'view/ModelView'

scene = null
nodeEditor = new NodeEditor -> scene

export getNodeEditor = -> nodeEditor

export install = (name) ->
    scene = basegl.scene {domElement: name}
    getNodeEditor().initialize()

export onEvent = subscribeEvents

main = -> install 'basegl-root'

window.run = main

debug = ->
    main()
    nodeEditor.setNodes [
        new ExpressionNode
            key: 1
            name: "foo"
            position: [0,0]
        new ExpressionNode
            key: 2
            name: "bar"
            position: [300,100]
        ]
    subscribeEvents (path, event) =>
        console.warn {path: path, base: event}
    window.n = getNodeEditor()

# debug()