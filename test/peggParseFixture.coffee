module.exports =

  deleteCard:
    find:
      Pref: [
        { objectId: 'bFowpZCxBt' }
        { objectId: 'AzyP6t2uzl' }
      ]
      Pegg: [
        { objectId: 'TcRJtKiiT8' }
        { objectId: 'vmPKPvIQCX' }
      ]
      PeggCounts: [
        { objectId: 'Gq8zXIUOVT' }
        { objectId: 'qabbGBDwWZ' }
      ]
      PrefCounts: [
        { objectId: 'bvzqd0FpEI' }
        { objectId: '5piSheXFE0' }
      ]
      Activity: [
        { objectId: 'VN6Vp4GUJL' }
        { objectId: 'OBm7DXGc9V' }
      ]
      Choice: [
        { objectId: '2CLncj0I2N' }
        { objectId: '9KMhvoeT5X' }
      ]
      Comment: [
        { objectId: 'UMKZeNXF3F' }
        { objectId: 'CYI3i9Kp4M' }
      ]
      Favorite: [
        { objectId: 'Tp7UgIwRVl' }
        { objectId: 'CAQZ8SifwW' }
      ]
      Frown: [
        { objectId: '7QUHmJMEk9' }
        { objectId: 'Uiasc7g48s' }
      ]

  resetUser:
    find:
      # Activity: [
      #   { objectId: 'VN6Vp4GUJL' }
      #   { objectId: 'OBm7DXGc9V' }
      # ]
      # Comment: [
      #   { objectId: 'UMKZeNXF3F' }
      #   { objectId: 'CYI3i9Kp4M' }
      # ]
      # Favorite: [
      #   { objectId: 'Tp7UgIwRVl' }
      #   { objectId: 'CAQZ8SifwW' }
      # ]
      # Flag: [
      #   { objectId: '2CLncj0I2N' }
      #   { objectId: '9KMhvoeT5X' }
      # ]
      # Frown: [
      #   { objectId: '7QUHmJMEk9' }
      #   { objectId: 'Uiasc7g48s' }
      # ]
      Pegg: [
        { objectId: 'TcRJtKiiT8' }
        { objectId: 'vmPKPvIQCX' }
      ]
      # PeggCounts: [
      #   { objectId: 'Gq8zXIUOVT' }
      #   { objectId: 'qabbGBDwWZ' }
      # ]
      # PeggerPoints: [
      #   { objectId: 'Gq8zXIUOVT' }
      #   { objectId: 'qabbGBDwWZ' }
      # ]
      Pref: [
        { objectId: 'bFowpZCxBt' }
        { objectId: 'AzyP6t2uzl' }
      ]
      # PrefCounts: [
      #   { objectId: 'bvzqd0FpEI' }
      #   { objectId: '5piSheXFE0' }
      # ]
      # PrefMatch: [
      #   { objectId: 'bvzqd0FpEI' }
      #   { objectId: '5piSheXFE0' }
      # ]
      # SupportComment: [
      #   { objectId: 'bvzqd0FpEI' }
      #   { objectId: '5piSheXFE0' }
      # ]
      # UserMood: [
      #   { objectId: 'bvzqd0FpEI' }
      #   { objectId: '5piSheXFE0' }
      # ]
      # UserSetting: [
      #   { objectId: 'bvzqd0FpEI' }
      #   { objectId: '5piSheXFE0' }
      # ]

    findMany:
      Card: [
        {
          objectId: 'bFowpZCxBt'
          hasPreffed: [
            'bvzqd0FpEI', '5piSheXFE0', 'VN6Vp4GUJL', 'OBm7DXGc9V', '2CLncj0I2N', '9KMhvoeT5X',
            'UMKZeNXF3F', 'CYI3i9Kp4M', 'Tp7UgIwRVl', 'CAQZ8SifwW', '7QUHmJMEk9', 'Uiasc7g48s'
          ]
        }
        {
          objectId: 'AzyP6t2uzl'
          hasPreffed: [
            'bvzqd0FpEI', '5piSheXFE0', 'VN6Vp4GUJL', 'OBm7DXGc9V', '2CLncj0I2N', '9KMhvoeT5X',
            'UMKZeNXF3F', 'CYI3i9Kp4M', 'Tp7UgIwRVl', 'CAQZ8SifwW', '7QUHmJMEk9', 'Uiasc7g48s'
          ]
        }
      ]

      Pref: [
        {
          objectId: 'TcRJtKiiT8'
          hasPegged: [
            'bvzqd0FpEI', '5piSheXFE0', 'VN6Vp4GUJL', 'OBm7DXGc9V', '2CLncj0I2N', '9KMhvoeT5X',
            'UMKZeNXF3F', 'CYI3i9Kp4M', 'Tp7UgIwRVl', 'CAQZ8SifwW', '7QUHmJMEk9', 'Uiasc7g48s'
          ]
        }
        {
          objectId: 'vmPKPvIQCX'
          hasPegged: [
            'bvzqd0FpEI', '5piSheXFE0', 'VN6Vp4GUJL', 'OBm7DXGc9V', '2CLncj0I2N', '9KMhvoeT5X',
            'UMKZeNXF3F', 'CYI3i9Kp4M', 'Tp7UgIwRVl', 'CAQZ8SifwW', '7QUHmJMEk9', 'Uiasc7g48s'
          ]
        }
      ]



