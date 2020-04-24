/*
 * Copyright 2020  Łukasz Wojniłowicz <lukasz.wojnilowicz@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef STORAGE_GPG_FRONTEND_WIDGET_KEYSSELECTOR_H
#define STORAGE_GPG_FRONTEND_WIDGET_KEYSSELECTOR_H

// ----------------------------------------------------------------------------
// KDE Includes

// ----------------------------------------------------------------------------
// QT Includes

// ----------------------------------------------------------------------------
// Project Includes

#include "gpg/frontend/keysselector.h"

namespace Storage {
namespace Gpg {
class KeysModel;
class UnusedKeysSelector;
  
namespace Widget {

class KeysSelectorPrivate;
class KeysSelector : public Gpg::KeysSelector
{
  Q_OBJECT
  Q_DECLARE_PRIVATE(KeysSelector)

public:
  KeysSelector();
  ~KeysSelector() override final;

  QObject *uiPart() override final;

private Q_SLOTS:
  void slotAddKeysClicked();
  void slotRemoveKeysClicked();

};

} // namespace Widget
} // namespace Gpg
} // namespace Storage

#endif