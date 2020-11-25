//
//  MinimizableView.swift

//
//  Created by Dominik Butz on 7/10/2019.
//  Copyright © 2019 Duoyun. All rights reserved.
//Version 0.3.2

import SwiftUI
import Combine


/**
MinimizableView.
*/
public struct MinimizableView<MainContent: View, CompactContent: View, BackgroundView: View>: View {
    
    /**
    MinimizableView Handler. must be attached to the MinimizableView.
    */
    @EnvironmentObject var minimizableViewHandler: MinimizableViewHandler

    var geometry: GeometryProxy
    var contentView:  MainContent
    var compactView: CompactContent
    var backgroundView: BackgroundView
    var settings: MiniSettings
    
    var offsetY: CGFloat {
         
        if self.minimizableViewHandler.isPresented == false {
            return UIScreen.main.bounds.height + 30  // safety margin for shadow etc.
         } else {
             // is presenting
            if self.minimizableViewHandler.isMinimized {
                return self.minimizableViewHandler.draggedOffsetY < 0 ? self.minimizableViewHandler.draggedOffsetY / 2: 0
            } else {
                // in expanded state, only return offset > 0 if dragging down
                return self.minimizableViewHandler.draggedOffsetY
                // return self.minimizableViewHandler.draggedOffset.height > 0 ? self.minimizableViewHandler.draggedOffset.height  : 0
            }
           
         }

     }
     
    var frameHeight: CGFloat? {
         
        if self.minimizableViewHandler.isMinimized {
            
            let draggedOffset: CGFloat = self.minimizableViewHandler.draggedOffsetY < 0 ? self.minimizableViewHandler.draggedOffsetY * (-1) : 0
            let height = self.minimizableViewHandler.isVisible ? self.settings.minimizedHeight + draggedOffset : 0
            return height
         } else {
            return self.settings.overrideHeight
            //return geometry.size.height - self.minimizableViewHandler.settings.expandedTopMargin
         }
     }
    
    var minimizedOffsetY: CGFloat {
        return self.minimizableViewHandler.isMinimized ? -self.settings.minimizedBottomMargin - geometry.safeAreaInsets.bottom  - self.minimizableViewHandler.draggedOffsetY / 2 : 0
    }
    
//    var positionY: CGFloat {
//        let totalHeight = maxSize.height
//
//        if self.minimizableViewHandler.isMinimized {
//
//            return totalHeight - self.minimizableViewHandler.settings.expandedTopMargin - self.minimizableViewHandler.settings.bottomMargin - self.minimizableViewHandler.settings.minimizedHeight
//
//        } else {
//            return (totalHeight / 2) - self.minimizableViewHandler.settings.expandedTopMargin
//
//        }
//    }


    /**
    MinimizableView Initializer.

    - Parameter content: the view that should be embedded inside the MinimizableView. Important: cast the view to: AnyView(yourView).
     
    - Parameter compactView: a view that will be shown at the top of the MinimizableView in minimized state. Pass in EmptyView() if you prefer changing the top part of your content view instead.
     
    - Parameter backgroundView: Pass in a background view. Don't set its frame.
     
    - Parameter geometry: Embed the ZStack, in which the MinimizableView resides, in a geometry reader.  This will allow the MinimizableView to adapt to a changing screen orientation.
     
    - Parameter settings: Minimizable View settings.
    */
    public init(@ViewBuilder content: ()->MainContent, compactView: ()->CompactContent, backgroundView: ()->BackgroundView, geometry: GeometryProxy, settings: MiniSettings) {
        
        self.contentView = content()
        self.compactView = compactView()
        self.backgroundView = backgroundView()
        self.geometry = geometry
        self.settings = settings

    }
    
    /**
       Body of MinimizableView.
    */
    public var body: some View {
  
            ZStack(alignment: .top) {
                if self.minimizableViewHandler.isPresented == true {
                    self.contentView
                  
                    if self.minimizableViewHandler.isMinimized && (self.compactView is EmptyView) == false {
                        self.compactView
                       
                    }
               }
            }
            .frame(width: geometry.size.width - self.settings.lateralMargin * 2 ,
                  height: self.frameHeight)
          //  .clipShape(RoundedRectangle(cornerRadius: self.minimizableViewHandler.settings.cornerRadius))
            .background(self.backgroundView)
         // .position(CGPoint(x: maxSize.width / 2, y: self.positionY))
            .offset(y: self.offsetY)
            .offset(y: self.minimizedOffsetY)
            .animation(self.settings.animation)
        
    }
    
}

struct MinimizableViewModifier<MainContent: View, CompactContent:View, BackgroundView: View>: ViewModifier {
     @EnvironmentObject var minimizableViewHandler: MinimizableViewHandler
        
      var contentView:  ()-> MainContent
      var compactView: ()-> CompactContent
      var backgroundView: ()->BackgroundView
    
      var dragOnChanged: (DragGesture.Value)->()
     var dragOnEnded: (DragGesture.Value)->()
      var geometry: GeometryProxy
        var settings: MiniSettings
    
    func body(content: Content) -> some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
       
            content
 
            MinimizableView(content: contentView, compactView: compactView, backgroundView: backgroundView, geometry: geometry, settings: settings)
                .gesture(DragGesture().onChanged(self.dragOnChanged).onEnded(self.dragOnEnded)).environmentObject(self.minimizableViewHandler)
            
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

public extension View {
    
    /**
    MinimizableView Initializer.

    - Parameter content: the view that should be embedded inside the MinimizableView. Important: cast the view to: AnyView(yourView).
     
    - Parameter compactView: a view that will be shown at the top of the MinimizableView in minimized state. Pass in EmptyView() if you prefer changing the top part of your content view instead.
     
    - Parameter backgroundView: Pass in a background view. Don't set its frame.
     
    - Parameter dragOnChanged: Determine what happens when the user vertically drags the miniView.
     
    - Parameter dragOnEnded: Determine what should happen when the user released the miniView after dragging.
     
    - Parameter geometry: Embed the ZStack, in which the MinimizableView resides, in a geometry reader.  This will allow the MinimizableView to adapt to a changing screen orientation.

    - Parameter settings: Minimizable View Settings.
    */
    func minimizableView<MainContent: View, CompactContent: View, BackgroundView: View>(@ViewBuilder content: @escaping ()->MainContent, compactView: @escaping ()->CompactContent, backgroundView: @escaping ()->BackgroundView, dragOnChanged: @escaping (DragGesture.Value)->(), dragOnEnded: @escaping (DragGesture.Value)->(), geometry: GeometryProxy, settings: MiniSettings = MiniSettings())->some View  {
        self.modifier(MinimizableViewModifier(contentView: content, compactView: compactView, backgroundView: backgroundView, dragOnChanged: dragOnChanged, dragOnEnded: dragOnEnded, geometry: geometry, settings: settings))
    }
    
}





