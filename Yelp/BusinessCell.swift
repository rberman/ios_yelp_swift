//
//  BusinessCell.swift
//  Yelp
//
//  Created by ruthie_berman on 9/20/17.
//  Copyright © 2017 Timothy Lee. All rights reserved.
//

import UIKit

class BusinessCell: UITableViewCell {

  @IBOutlet weak var thumbImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var ratingImageView: UIImageView!
  @IBOutlet weak var reviewsCountLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var categoriesLabel: UILabel!

  var business : Business! {
    didSet {
      if business.imageURL != nil {
        thumbImageView.setImageWith(business.imageURL!)
      } else {
        thumbImageView.image = #imageLiteral(resourceName: "business-placeholder-image")
      }
      nameLabel.text = business.name
      distanceLabel.text = business.distance
      ratingImageView.setImageWith(business.ratingImageURL!)
      reviewsCountLabel.text = "\(business.reviewCount ?? 0) Reviews"
      addressLabel.text = business.address
      categoriesLabel.text = business.categories
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    thumbImageView.layer.cornerRadius = 3
    thumbImageView.clipsToBounds = true

    nameLabel.preferredMaxLayoutWidth = nameLabel.frame.size.width
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    nameLabel.preferredMaxLayoutWidth = nameLabel.frame.size.width
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

}
