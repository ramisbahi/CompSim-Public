//
//  SlideSegue.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/27/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class SlideRightSegue: UIStoryboardSegue {

    override func perform()
    {
        let src = self.source
        let dst = self.destination

        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: -src.view.frame.size.width, y: 0)

        UIView.animate(withDuration: 0.25,
                              delay: 0.0,
                            options: .curveEaseInOut,
                         animations: {
                                dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
                                },
                        completion: { finished in
                                src.present(dst, animated: false, completion: nil)
                                    }
                        )
    }
}
